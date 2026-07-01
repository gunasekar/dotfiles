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
  local state = { counts = {}, idx = 0, next = opts.start }
  local label = opts.label or function(_, i) return "Session " .. i end

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

  -- Remove sessions whose buffers have been closed/killed
  local function prune()
    local alive, shift = {}, 0
    for i, c in ipairs(state.counts) do
      local t = get_term(c)
      if t and t:buf_valid() then
        table.insert(alive, c)
      elseif i <= state.idx then
        shift = shift + 1
      end
    end
    state.counts = alive
    state.idx = math.max(0, math.min(state.idx - shift, #state.counts))
  end

  local function show(idx)
    hide_all()
    state.idx = idx
    local t = get_term(state.counts[idx])
    if t and t:buf_valid() then
      if not t:valid() then t:show() end
      t:focus()
      focus_term()
    end
  end

  local function new_session()
    prune()
    hide_all()
    local count = state.next
    state.next = state.next + 1
    table.insert(state.counts, count)
    state.idx = #state.counts
    Snacks.terminal.toggle(opts.cmd, opts.win_opts(count))
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
