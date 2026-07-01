-- AI agent integrations
-- Right panel: unified fzf agent picker — <C-\> toggles, <C-S-\> opens a new session.
-- All terminal UI is handled by the session table below.
-- claudecode.nvim runs as a background WebSocket server so ClaudeCodeSend and
-- diff integration work; it does not manage the terminal itself.

-- ── In-terminal keybindings (shared by all right-panel sessions) ───────────
local function agent_terminal_keys(name)
  return {
    -- Single <Esc> exits terminal mode (snacks default requires double-<Esc>)
    term_normal = {
      "<Esc>",
      function()
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
          "n", false
        )
      end,
      mode = "t",
      desc = "Esc to normal mode",
    },
    -- <C-Esc> forwards ESC to the agent process (interrupt/cancel)
    term_interrupt = {
      "<C-Esc>",
      function()
        local chan = vim.bo.channel
        if chan and chan > 0 then
          vim.api.nvim_chan_send(chan, "\27")
        end
      end,
      mode = "t",
      desc = "Ctrl-Esc interrupt to " .. name,
    },
  }
end

-- ── Agent picker ───────────────────────────────────────────────────────────
-- fzf runs inside the terminal on first open; exec replaces the shell so the
-- buffer stays live after the agent starts.
-- To add/remove agents, edit scripts/agent-picker.sh in this config directory.
local AGENT_CMD = vim.fn.stdpath("config") .. "/scripts/agent-picker.sh"

local function right_win_opts(count)
  return {
    win = {
      position = "right",
      width = 0.4,
      wo = { winhighlight = "Normal:Normal,NormalFloat:Normal" },
      keys = agent_terminal_keys("Agent"),
    },
    count = count,
  }
end

-- ── Session state ──────────────────────────────────────────────────────────
-- Each session is identified by a unique `count` (snacks terminal ID).
-- Counts start at 100 to avoid collision with bottom-panel terminals (1, 2).
local right = { counts = {}, idx = 0, next = 100 }

local function get_term(count)
  return Snacks.terminal.get(
    AGENT_CMD,
    vim.tbl_extend("force", right_win_opts(count), { create = false })
  )
end

local function focus_term()
  local buf = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())
  if vim.bo[buf].buftype == "terminal" then
    vim.cmd("startinsert")
  end
end

local function hide_all()
  for _, c in ipairs(right.counts) do
    local t = get_term(c)
    if t and t:valid() then t:hide() end
  end
end

-- Remove sessions whose buffers have been closed/killed
local function prune()
  local alive, shift = {}, 0
  for i, c in ipairs(right.counts) do
    local t = get_term(c)
    if t and t:buf_valid() then
      table.insert(alive, c)
    elseif i <= right.idx then
      shift = shift + 1
    end
  end
  right.counts = alive
  right.idx = math.max(0, math.min(right.idx - shift, #right.counts))
end

local function show_session(idx)
  hide_all()
  right.idx = idx
  local t = get_term(right.counts[idx])
  if t and t:buf_valid() then
    if not t:valid() then t:show() end
    t:focus()
    focus_term()
  end
end

-- ── Context sender ─────────────────────────────────────────────────────────
-- After `exec $agent` the shell is replaced in-place, so jobpid(chan) IS the
-- agent's PID. We ps it to decide which send path to take.
local function detect_agent(chan)
  local pid = vim.fn.jobpid(chan)
  if not pid or pid <= 0 then return nil end
  local comm = vim.fn.system("ps -o comm= -p " .. pid):gsub("%s+$", "")
  if comm == "claude" then return "claude" end
  local args = vim.fn.system("ps -o args= -p " .. pid):gsub("%s+$", "")
  if args:find("cursor-agent", 1, true) then return "cursor-agent" end
  return nil
end

local function send_context_to_agent()
  prune()
  if #right.counts == 0 or right.idx == 0 then
    vim.notify("Open an agent session first (<C-\\>)", vim.log.levels.WARN)
    return
  end
  local t = get_term(right.counts[right.idx])
  if not t or not t:buf_valid() then
    vim.notify("No active agent session", vim.log.levels.WARN)
    return
  end
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end
  local chan = vim.bo[t.buf].channel
  if not chan or chan == 0 then
    vim.notify("Agent terminal not ready", vim.log.levels.WARN)
    return
  end

  -- For claude, the WebSocket path gives richer context than terminal input
  if detect_agent(chan) == "claude" then
    vim.cmd("ClaudeCodeSend")
    return
  end

  -- cursor-agent (or still at fzf picker): type a code fence into the terminal.
  -- Determine range: prefer an active/recent visual selection, fall back to line.
  local mode = vim.fn.mode()
  local s, e
  if mode == "v" or mode == "V" or mode == "\22" then
    s, e = vim.fn.line("v"), vim.fn.line(".")
  else
    s, e = vim.fn.line("'<"), vim.fn.line("'>")
  end
  if not s or s <= 0 or not e or e <= 0 then
    -- No selection available: send file:line reference only
    vim.api.nvim_chan_send(chan, path .. ":" .. vim.fn.line(".") .. " ")
    show_session(right.idx)
    return
  end
  if s > e then s, e = e, s end

  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  local ft    = vim.bo.filetype
  local text  = string.format(
    "```%s\n# %s:%d-%d\n%s\n```",
    ft ~= "" and ft or "text", path, s, e, table.concat(lines, "\n")
  )
  -- Bracketed paste tells cursor-agent's TUI this is pasted text so newlines
  -- inside the block don't trigger an accidental submit.
  vim.api.nvim_chan_send(chan, "\x1b[200~" .. text .. "\x1b[201~")
  show_session(right.idx)
end

-- ── Actions ────────────────────────────────────────────────────────────────
local function new_right_session()
  prune()
  hide_all()
  local count = right.next
  right.next = right.next + 1
  table.insert(right.counts, count)
  right.idx = #right.counts
  Snacks.terminal.toggle(AGENT_CMD, right_win_opts(count))
end

local function toggle_right_panel()
  prune()
  if #right.counts == 0 or right.idx == 0 then
    new_right_session()
    return
  end
  local t = get_term(right.counts[right.idx])
  if not t then
    new_right_session()
    return
  end
  if t:valid() then
    if vim.api.nvim_get_current_win() == t.win then
      t:hide()
    else
      show_session(right.idx)
    end
  else
    show_session(right.idx)
  end
end

local function next_right_session()
  prune()
  if #right.counts < 2 then return end
  show_session((right.idx % #right.counts) + 1)
end

local function prev_right_session()
  prune()
  if #right.counts < 2 then return end
  show_session(((right.idx - 2) % #right.counts) + 1)
end

-- ── Plugin specs ───────────────────────────────────────────────────────────
return {
  -- claudecode.nvim: WebSocket server + ClaudeCodeSend only.
  -- Terminal UI is handled by our fzf session manager above.
  -- When claude runs in our snacks terminal it inherits CLAUDE_NVIM_IPC_*
  -- env vars and connects to this WebSocket, enabling selection send + diff view.
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      auto_start = true,
      log_level = "info",
      git_repo_cwd = true,
      -- Disable claudecode.nvim's own terminal management entirely.
      -- Our snacks session manager owns the terminal; claudecode only provides
      -- the WebSocket IPC that ClaudeCodeSend and diff integration depend on.
      terminal = { provider = "none" },
      diff = {
        auto_close_on_accept = true,
        vertical_split = true,
        open_in_current_tab = true,
        keep_terminal_focus = true,
      },
      focus_after_send = false,
    },
    keys = {
      { "<C-\\>",     toggle_right_panel, mode = { "n", "i", "v", "t" }, desc = "Toggle right panel" },
      { "<C-S-\\>",   new_right_session,  mode = { "n", "i", "v", "t" }, desc = "New agent session" },
      { "<leader>ac", toggle_right_panel, desc = "Toggle right panel" },
      { "<C-S-]>",    next_right_session,  mode = { "n", "i", "v", "t" }, desc = "Next agent session" },
      { "<C-S-[>",    prev_right_session,  mode = { "n", "i", "v", "t" }, desc = "Prev agent session" },
      { "<leader>a]", next_right_session, desc = "Next agent session" },
      { "<leader>a[", prev_right_session, desc = "Prev agent session" },
      { "<leader>as", send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
      { "<C-S-.>",    send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
      { "<D-S-.>",    send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
    },
  },
}
