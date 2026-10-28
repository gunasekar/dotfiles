-- AI agent integrations
-- Right panel: unified fzf agent picker — <C-\> toggles, <C-S-\> opens a new session.
-- All terminal UI is handled by the session table below.
--
-- No plugin backs any of this. The agents are started by `trails` (github.com/gunasekar/trails,
-- installed from the gunasekar/tap Homebrew tap), which runs the picked CLI in its own tmux session; nvim only hosts the terminal, and the
-- session outlives it either way.
--
-- claudecode.nvim used to sit here as a background WebSocket server for ClaudeCodeSend and
-- claude's in-editor diff view, and it is gone because that connection was never actually
-- made. claude auto-connects to an IDE only when it inherits CLAUDE_CODE_SSE_PORT and
-- ENABLE_IDE_INTEGRATION, and claudecode exports those from one place: its own terminal
-- provider (claudecode/terminal.lua), which this config set to "none" because the session
-- manager below owns the terminal. So the server ran and wrote a lockfile into ~/.claude/ide
-- that nothing read unless you typed /ide by hand inside claude. Restoring the integration
-- means handing claude those two env vars, not re-adding the spec.
--
-- Its `keys` table was also what registered every mapping in this file, so those are set
-- directly at the bottom now. This file is still a lazy spec (it returns one), so it is
-- evaluated during setup and the mappings land before anything can press them.

-- ── In-terminal keybindings (shared by all right-panel sessions) ───────────
-- The mouse and wheel handling is shared with the bottom panel (util/panels.lua);
-- what is added here is agent-specific and deliberately not given to a shell.
-- <Esc> is the one that must not spread: down there it belongs to whatever is at
-- the prompt — the zsh line editor, an fzf overlay, a TUI you started — and
-- taking it for "leave terminal mode" would be a regression nobody asked for.
local function agent_terminal_keys(name)
  return vim.tbl_extend("error", require("util.panels").terminal_keys(), {
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
  })
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
-- To add/remove agents, edit trails' config (~/.config/trails/config.json, `trails config`).
--
-- Resolved to an absolute path when it can be, so the terminal's buffer name ends in
-- /trails and edgy files it in the right slot (plugins/ui/edgy.lua). The bare name is the
-- fallback: the panel then says "trails: command not found" rather than opening nothing.
local AGENT_CMD = vim.fn.exepath("trails") ~= "" and vim.fn.exepath("trails") or "trails"

-- Why there is no `relative = "win"` here, unlike the bottom panel (which sets
-- it in plugins/editor/snacks.lua, off the shared editor_win in util/panels.lua).
-- Nothing below describes code that is present — it records an alternative that
-- was tried and reverted, so the asymmetry between the two panels doesn't read
-- as an oversight worth "fixing".
--
-- The asymmetry is edgy's: the bottom slot spans exactly the editor window's width
-- and states its own height, so a win-relative split is already the right size.
-- The right slot spans the *full screen height*, and the editor window does not
-- — it is short by the bottom panel's 20 rows plus its statusline whenever the
-- shell is open. Measured on a live layout: editor 74 rows, right slot 95.
--
-- So splitting the editor window here (`vertical rightbelow` inside it, snacks
-- win.lua) would bear the agent at 74 rows for edgy to stretch to 95, and a
-- 21-row resize is a real SIGWINCH — the agent repaints its whole frame and
-- strands the previous one above. `relative = "editor"` is `vertical botright`:
-- full height from the start, so the agent lands at its final size in one step.
--
-- The measurement that once called win-relative free on this side (identical
-- 88x53, with and without) was taken with the bottom panel closed. There the
-- editor window *is* full height and there is no discrepancy to find — verified,
-- a second nvim with no bottom panel reports editor 95 and agent 95. Reproduce
-- with the shell open or the answer is meaningless.
--
-- The cost is real and accepted: this full-screen split re-lays-out every window,
-- putting the bottom shell through three passes (220x20 → 109x20 → 110x53 →
-- 131x20) rather than one, the middle one handing it 53 rows instead of 20. zsh
-- redrawing its prompt is cheaper than a stranded agent frame, which sits there
-- until something repaints it.
local function right_win_opts(count)
  return {
    win = {
      position = "right",
      width = 0.4,
      -- Pin the winbar off. Snacks gives every non-float terminal one
      -- ("<id>: <term_title>", snacks/terminal.lua) and nothing else takes it
      -- away: `winbar = false` on edgy's right slot means "don't add an edgy
      -- winbar", not "remove that one" — it sets the value to nil and the apply
      -- loop skips the key (edgy/window.lua). Measured: drop this pin and the
      -- winbar is still there a layout pass later.
      --
      -- So this is the only thing turning it off, and the reason isn't the
      -- one-row resize an earlier version of this comment claimed — there is no
      -- flip to race, the winbar simply stays. What the pin buys is a grid equal
      -- to nvim_win_get_height, which is the alternate-screen test the wheel
      -- handling in util/panels.lua depends on. Leave it out and scrolling this
      -- panel in normal mode silently stops working.
      wo = { winhighlight = "Normal:Normal,NormalFloat:Normal", winbar = "" },
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

  -- One path for every agent (and for the fzf picker itself, before one is chosen):
  -- type a code fence into the terminal. claude took a ClaudeCodeSend branch here until
  -- claudecode.nvim was removed — see the header for why that path was never live.
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

-- ── Keymaps ────────────────────────────────────────────────────────────────
-- Set here rather than carried by a plugin spec's `keys`, because there is no longer a
-- plugin to hang them off. Nothing is lost by that: `keys` exists to defer *loading* a
-- plugin until first press, and every handler below is a closure over the session manager
-- this file already built at spec-eval time. Snacks is `lazy = false` (plugins/editor/
-- snacks.lua), so the terminal API they reach for is up before any of these can fire.
--
-- silent = true is a choice here, not parity: lazy has no default for it. Its Keys.opts()
-- (lazy/core/handler/keys.lua) copies a spec's fields verbatim minus {mode, id, ft, rhs,
-- lhs} and never adds silent, so these mappings ran at vim.keymap.set's own default of
-- false until now. Nothing observable changes either way — every rhs below is a Lua
-- function, and those do not echo the way a :cmd<CR> mapping does.
--
-- Ctrl+Shift+<punctuation> arrives under two different names depending on the terminal
-- in front of tmux, so each one is bound twice.
--
-- kitty reports the *base* key, Ctrl+Shift+\ as <C-S-\>: directly through the Kitty
-- keyboard protocol, and inside tmux as CSI-u, since kitty ignores tmux's modifyOtherKeys
-- request and Ctrl+Shift+<key> has no legacy encoding to fall back to. A terminal that
-- does speak modifyOtherKeys to tmux (Zed's, or another terminal over ssh) reports the
-- *shifted* character, so the same physical keypress arrives as <C-S-|>. Both verified
-- by which mapping fires.
--
-- Letters are unaffected (<C-S-L> resolves identically both ways); only shifted
-- punctuation splits:  \ →|   ] →}   [ →{   . →>
local maps = {
  { "<C-\\>",     sessions.toggle, mode = { "n", "i", "v", "t" }, desc = "Toggle right panel" },
  { "<C-S-\\>",   sessions.new,    mode = { "n", "i", "v", "t" }, desc = "New agent session" },
  { "<C-S-|>",    sessions.new,    mode = { "n", "i", "v", "t" }, desc = "New agent session (tmux)" },
  { "<leader>ac", sessions.toggle, desc = "Toggle right panel" },
  { "<C-S-]>",    sessions.next,   mode = { "n", "i", "v", "t" }, desc = "Next agent session" },
  { "<C-S-}>",    sessions.next,   mode = { "n", "i", "v", "t" }, desc = "Next agent session (tmux)" },
  { "<C-S-[>",    sessions.prev,   mode = { "n", "i", "v", "t" }, desc = "Prev agent session" },
  { "<C-S-{>",    sessions.prev,   mode = { "n", "i", "v", "t" }, desc = "Prev agent session (tmux)" },
  { "<leader>a]", sessions.next, desc = "Next agent session" },
  { "<leader>a[", sessions.prev, desc = "Prev agent session" },
  { "<leader>as", send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
  { "<C-S-.>",    send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
  { "<C-S->>",    send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent (tmux)" },
  { "<D-S-.>",    send_context_to_agent, mode = { "n", "v" }, desc = "Send context to agent" },
}

for _, m in ipairs(maps) do
  vim.keymap.set(m.mode or "n", m[1], m[2], { desc = m.desc, silent = true })
end

-- A spec file has to return one. Everything this file does is above.
return {}
