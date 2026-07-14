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
-- fzf runs inside the terminal on first open, and the agent it picks runs in its
-- own tmux session, so it outlives this panel (and nvim itself) — reattach from
-- here, a Zed thread or a plain shell.
--
-- No `exec` needed here, unlike Zed's terminal_init_command: Snacks runs this
-- through `$SHELL -c`, which exits on its own when the agent quits. Zed runs its
-- command inside an *interactive* shell that would otherwise outlive the agent
-- and leave you at a stray prompt.
--
-- To add/remove agents, edit ~/.dotfiles/bin/.local/bin/aigent (the bin package).
local AGENT_CMD = vim.env.HOME .. "/.dotfiles/bin/.local/bin/aigent"

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

-- ── Session state ──────────────────────────────────────────────────────────
-- Each session is identified by a unique `count` (snacks terminal ID).
-- Counts start at 100 to avoid collision with bottom-panel terminals.
local sessions = require("util.term_sessions").new({
  name = "Agent",
  cmd = AGENT_CMD,
  win_opts = right_win_opts,
  start = 100,
  label = function(t, i)
    local chan = vim.bo[t.buf].channel
    local agent = chan and chan > 0 and detect_agent(chan) or nil
    return "Session " .. i .. (agent and (" (" .. agent .. ")") or "")
  end,
})

local function send_context_to_agent()
  local t = sessions.current()
  if not t then
    vim.notify("Open an agent session first (<C-\\>)", vim.log.levels.WARN)
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
    sessions.focus()
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
  sessions.focus()
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
      { "<C-\\>",     sessions.toggle, mode = { "n", "i", "v", "t" }, desc = "Toggle right panel" },
      { "<C-S-\\>",   sessions.new,    mode = { "n", "i", "v", "t" }, desc = "New agent session" },
      { "<leader>ac", sessions.toggle, desc = "Toggle right panel" },
      { "<C-S-]>",    sessions.next,   mode = { "n", "i", "v", "t" }, desc = "Next agent session" },
      { "<C-S-[>",    sessions.prev,   mode = { "n", "i", "v", "t" }, desc = "Prev agent session" },
      { "<leader>a]", sessions.next, desc = "Next agent session" },
      { "<leader>a[", sessions.prev, desc = "Prev agent session" },
      { "<leader>as", send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
      { "<C-S-.>",    send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
      { "<D-S-.>",    send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
    },
  },
}
