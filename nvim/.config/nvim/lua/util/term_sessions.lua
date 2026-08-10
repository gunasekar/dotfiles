-- Generic multi-instance snacks.terminal session manager: toggle/new/next/prev
-- over a list of terminals identified by snacks count IDs. Used by both the
-- right-panel agent picker and the bottom-panel shell so panel-switching
-- behavior stays identical everywhere it's needed.
--
-- Each manager registers itself (by opts.name) so M.picker() can offer every
-- tracked session across every manager in one list, alongside edgy's other
-- (non-session) panels — edgy itself only knows about currently *visible*
-- windows, so it can't list sessions we've hidden in the background.
local M = {}

-- Ordered so the picker lists managers in creation order.
local managers = {}

-- opts.name:     label prefix for this manager's sessions in M.picker()
-- opts.cmd:      command Snacks.terminal runs (nil = default shell)
-- opts.win_opts: function(count) -> snacks.terminal.Opts for that session
-- opts.start:    first count ID this manager hands out (must not collide
--                with other snacks.terminal session managers)
-- opts.label:    optional function(term, idx) -> string, for custom
--                per-session labels (default: "<name> <idx>")
function M.new(opts)
  -- state.bufs maps terminal buffer -> count, so window events can be traced
  -- back to the session that owns them (see the WinClosed hook below).
  local state = { counts = {}, idx = 0, next = opts.start, bufs = {} }
  local label = opts.label or function(_, i) return "Session " .. i end
  local augroup = vim.api.nvim_create_augroup("term_sessions_" .. opts.name, { clear = true })

  local function get_term(count)
    return Snacks.terminal.get(opts.cmd, vim.tbl_extend("force", opts.win_opts(count), { create = false }))
  end

  local function focus_term()
    local buf = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())
    if vim.bo[buf].buftype == "terminal" then
      vim.cmd("startinsert")
    end
  end

  local function hide_all()
    for _, c in ipairs(state.counts) do
      local t = get_term(c)
      if t and t:valid() then t:hide() end
    end
  end

  -- A session is over once its buffer is gone. Command terminals (the agent
  -- panel) need the extra job check: when one exits while hidden, snacks leaves
  -- the buffer behind — a husk with a dead job that would otherwise keep its
  -- slot in the list and get cycled onto. A terminal that is still on screen is
  -- always kept, dead job or not: that's snacks holding a non-zero exit up so
  -- the error stays readable.
  local function is_dead(t)
    if not t or not t:buf_valid() then return true end
    if t:valid() then return false end
    local chan = vim.bo[t.buf].channel
    return not chan or chan <= 0 or vim.fn.jobwait({ chan }, 0)[1] ~= -1
  end

  -- Remove sessions whose buffers have been closed/killed
  local function prune()
    local alive, shift = {}, 0
    for i, c in ipairs(state.counts) do
      local t = get_term(c)
      if not is_dead(t) then
        table.insert(alive, c)
      else
        -- Don't leave the husk lying around as a stray terminal buffer.
        if t and t:buf_valid() then t:close() end
        if i <= state.idx then shift = shift + 1 end
      end
    end
    state.counts = alive
    for b in pairs(state.bufs) do
      if not vim.api.nvim_buf_is_valid(b) then state.bufs[b] = nil end
    end
    -- Closing the session *at* the current index walks idx down past the first
    -- slot — close session 1 of 2 and idx lands on 0 with a session still alive.
    -- toggle() reads idx == 0 as "nothing open" and spawns a new session on top
    -- of the survivors. Only an empty list may leave idx at 0.
    state.idx = math.min(state.idx - shift, #state.counts)
    state.idx = #state.counts > 0 and math.max(1, state.idx) or 0
  end

  local function show(idx)
    hide_all()
    state.idx = idx
    local t = get_term(state.counts[idx])
    if t and t:buf_valid() then
      if not t:valid() then
        -- A hidden terminal re-splits using the opts it was *created* with. If
        -- those name a window that has since been closed, snacks silently falls
        -- back to splitting the current window (snacks/win.lua) — which may be
        -- another panel. Re-resolve placement against the layout as it is now.
        local fresh = opts.win_opts(state.counts[idx]).win
        if fresh then t.opts = vim.tbl_extend("force", t.opts, fresh) end
        t:show()
      end
      t:focus()
      focus_term()
    end
  end

  -- When a session's process exits, snacks closes its window and wipes the
  -- buffer — which tears down the whole panel slot, even when other sessions
  -- are alive but hidden in the background. Nothing tells us about that (prune
  -- only runs on the next toggle/next/prev), so the panel just vanishes and the
  -- survivors are only reachable by toggling it back on. Put the next session
  -- up in the dead one's place instead.
  --
  -- Deferred, because the teardown is still in flight while we're being
  -- notified. By the time this runs the layout has settled, so a panel that's
  -- still occupied (a non-zero exit keeps the dead terminal on screen, with
  -- snacks reporting the error) is left exactly as it is.
  local pending = false
  local function replace(count)
    if pending or state.counts[state.idx] ~= count then return end
    pending = true
    vim.schedule(function()
      pending = false
      prune()
      if #state.counts == 0 then return end
      local cur = get_term(state.counts[state.idx])
      if cur and cur:valid() then return end
      show(state.idx)
    end)
  end

  -- Two events, because the two kinds of session tear down in opposite orders
  -- and each is only observable in one of them:
  --
  --   bottom panel (a shell, no cmd) — snacks' auto-close runs from a
  --   *buffer-local* TermClose, which Neovim dispatches ahead of global ones.
  --   By the time a TermClose hook of ours runs, the window is closed, the
  --   buffer wiped and the terminal dropped from snacks' registry: nothing
  --   left to identify. WinClosed fires first, with both still intact.
  --
  --   right panel (an agent, spawned with a cmd) — the reverse: our TermClose
  --   runs first with the window still open, and the WinClosed that follows
  --   can no longer be traced back to a buffer.
  --
  -- replace() is guarded, so a session that manages to trip both is fine.
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    callback = function(ev)
      local win = tonumber(ev.match)
      if not win or not vim.api.nvim_win_is_valid(win) then return end
      local buf = vim.api.nvim_win_get_buf(win)
      local count = state.bufs[buf]
      if not count then return end
      -- WinClosed also fires when the panel is merely hidden (toggle, `q`,
      -- :q), which must not resurface anything. A dead job is what marks a
      -- real exit: jobwait reports -1 while the process is still running, and
      -- the job is already reaped by the time snacks closes the window on exit.
      local chan = vim.bo[buf].channel
      if chan and chan > 0 and vim.fn.jobwait({ chan }, 0)[1] == -1 then return end
      replace(count)
    end,
  })

  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    callback = function(ev)
      local count = state.bufs[ev.buf]
      if not count then return end
      -- Only when this session is the one on screen: one exiting in the
      -- background has no window to replace, and must not pop the panel open.
      local t = get_term(count)
      if not (t and t:valid()) then return end
      replace(count)
    end,
  })

  local function new_session()
    prune()
    hide_all()
    local count = state.next
    state.next = state.next + 1
    table.insert(state.counts, count)
    state.idx = #state.counts
    local t = Snacks.terminal.toggle(opts.cmd, opts.win_opts(count))
    -- Buffer -> session, so the WinClosed hook above can tell this manager's
    -- terminals from every other snacks terminal on screen.
    if t and t.buf then state.bufs[t.buf] = count end
  end

  local function toggle()
    prune()
    if #state.counts == 0 or state.idx == 0 then
      new_session()
      return
    end
    local t = get_term(state.counts[state.idx])
    if not t then
      new_session()
      return
    end
    if t:valid() then
      if vim.api.nvim_get_current_win() == t.win then
        t:hide()
      else
        show(state.idx)
      end
    else
      show(state.idx)
    end
  end

  local function next_session()
    prune()
    if #state.counts < 2 then return end
    show((state.idx % #state.counts) + 1)
  end

  local function prev_session()
    prune()
    if #state.counts < 2 then return end
    show(((state.idx - 2) % #state.counts) + 1)
  end

  local mgr = {
    toggle = toggle,
    new = new_session,
    next = next_session,
    prev = prev_session,
    -- Unconditionally show/focus the current session (unlike toggle, never
    -- hides it), for callers that just sent it input and want it visible.
    focus = function()
      prune()
      if state.idx > 0 then show(state.idx) end
    end,
    -- Current session's terminal object (or nil if none/prune-worthy), for
    -- callers that need to send input to whichever session is active.
    current = function()
      prune()
      if #state.counts == 0 or state.idx == 0 then return nil end
      local t = get_term(state.counts[state.idx])
      if not t or not t:buf_valid() then return nil end
      return t
    end,
    -- All alive sessions, for callers building a picker over them.
    list = function()
      prune()
      local items = {}
      for i, c in ipairs(state.counts) do
        local t = get_term(c)
        if t then
          table.insert(items, { idx = i, label = label(t, i), is_current = i == state.idx })
        end
      end
      return items
    end,
    -- Jump directly to a specific session by its list() idx.
    goto_idx = function(idx)
      if state.counts[idx] then show(idx) end
    end,
  }

  table.insert(managers, { name = opts.name, mgr = mgr })
  return mgr
end

-- Combined picker over every registered manager's sessions, plus edgy's
-- other (non-session) panels, e.g. the file explorer.
function M.picker()
  local items = {}

  table.insert(items, {
    label = "[Panel] Explorer",
    action = function() require("edgy").select("left") end,
  })

  for _, entry in ipairs(managers) do
    for _, s in ipairs(entry.mgr.list()) do
      table.insert(items, {
        label = string.format("[%s] %s%s", entry.name, s.label, s.is_current and "  (current)" or ""),
        action = function() entry.mgr.goto_idx(s.idx) end,
      })
    end
  end

  vim.ui.select(items, {
    prompt = "Select panel or session:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if choice then choice.action() end
  end)
end

return M
