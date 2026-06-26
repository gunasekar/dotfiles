-- AI Assistant integrations

-- A Snacks shell terminal pinned to the right side that shares its slot with
-- the Claude Code panel: opening one hides the other (mutually exclusive). The
-- bottom toggleterm (<C-`>) is unrelated and untouched.
local NEO_TREE_WIDTH = 30

local function assistant_terminal_keys(name)
  return {
    -- Override Snacks' built-in "term_normal" key (its default makes a
    -- single <Esc> pass through to the terminal and only exits on a
    -- double <Esc>). Reusing the same key name replaces that default so a
    -- single <Esc> immediately leaves terminal mode like normal Neovim,
    -- WITHOUT reaching the assistant.
    term_normal = {
      "<Esc>",
      function()
        -- Leave terminal mode (mode "t"); stopinsert only handles Insert
        -- mode, so feed <C-\><C-n> instead.
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
          "n",
          false
        )
      end,
      mode = "t",
      desc = "Esc to Neovim normal mode",
    },
    -- <C-Esc> passes through to the assistant (interrupt/cancel last prompt).
    -- Requires a terminal that distinguishes <C-Esc> from <Esc> via the
    -- kitty keyboard protocol (Ghostty + Neovim 0.11 do, by default).
    term_interrupt = {
      "<C-Esc>",
      function()
        local chan = vim.bo.channel
        if chan and chan > 0 then
          vim.api.nvim_chan_send(chan, "\27") -- send ESC byte to the assistant
        end
      end,
      mode = "t",
      desc = "Ctrl-Esc to " .. name .. " (interrupt)",
    },
  }
end

local RIGHT_TERM_OPTS = {
  win = {
    position = "right",
    width = 0.4, -- match Claude's split_width_percentage
    wo = {
      winhighlight = "Normal:Normal,NormalFloat:Normal",
    },
    keys = assistant_terminal_keys("Cursor"),
  },
}

local function focus_terminal_window()
  if vim.bo.buftype == "terminal" then
    vim.cmd("startinsert")
  end
end

local function restore_neo_tree_width()
  local function restore()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) then
        local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
        if ok and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
          vim.wo[win].winfixwidth = true
          pcall(vim.api.nvim_win_set_width, win, NEO_TREE_WIDTH)
        end
      end
    end
  end

  -- Snacks and claudecode both schedule split equalization after open/close.
  -- Restore the explorer width after those layout callbacks have run.
  vim.schedule(function()
    restore()
    vim.defer_fn(restore, 20)
  end)
end

local function find_claude_win()
  local ok, ct = pcall(require, "claudecode.terminal")
  if not ok then
    return nil
  end
  local bufnr = ct.get_active_terminal_bufnr and ct.get_active_terminal_bufnr()
  if not bufnr then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      return win
    end
  end
  return nil
end

-- Hide the Claude Code panel if it is currently visible, WITHOUT killing the
-- session. :ClaudeCode runs simple_toggle, which hides a visible panel (and
-- preserves the buffer/process) rather than destroying it like ClaudeCodeClose.
local function hide_claude_if_visible()
  if find_claude_win() then
    pcall(vim.cmd, "ClaudeCode")
  end
end

-- Hide the right-side Snacks terminal if it is currently visible.
local function hide_right_term()
  local t = Snacks.terminal.get("cursor-agent", vim.tbl_deep_extend("force", {}, RIGHT_TERM_OPTS, { create = false }))
  if t and t:valid() then
    t:hide()
  end
end

-- Focus-aware Cursor terminal toggle, hiding Claude first only when opening
-- Cursor from a hidden/closed state.
local function toggle_right_term()
  local t = Snacks.terminal.get("cursor-agent", vim.tbl_deep_extend("force", {}, RIGHT_TERM_OPTS, { create = false }))
  if t then
    if t:valid() then
      if t.win == vim.api.nvim_get_current_win() then
        t:hide()
      else
        t:focus()
        focus_terminal_window()
      end
      restore_neo_tree_width()
      return
    elseif t:buf_valid() then
      hide_claude_if_visible()
      t:show()
      t:focus()
      focus_terminal_window()
      restore_neo_tree_width()
      return
    end
  end

  hide_claude_if_visible()
  Snacks.terminal.toggle("cursor-agent", RIGHT_TERM_OPTS)
  restore_neo_tree_width()
end

-- Focus-aware Claude toggle, hiding Cursor first only when opening Claude from
-- a hidden/closed state.
local function toggle_claude()
  if not find_claude_win() then
    hide_right_term()
  end
  vim.cmd("ClaudeCodeFocus")
  restore_neo_tree_width()
end

return {
  -- Claude Code integration
  {
    "coder/claudecode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      -- Server settings
      auto_start = true,
      log_level = "info",

      -- Launch Claude with permissions bypassed
      terminal_cmd = "claude --dangerously-skip-permissions",

      -- Terminal configuration
      terminal = {
        split_side = "right",          -- Position on right side
        split_width_percentage = 0.4,  -- 40% of screen width
        provider = "snacks",           -- Use snacks.nvim terminal
        auto_close = false,            -- Keep terminal open
        snacks_win_opts = {
          wo = {
            winhighlight = "Normal:Normal,NormalFloat:Normal", -- Match editor background
          },
          keys = assistant_terminal_keys("Claude"),
        },
      },

      -- Working directory
      git_repo_cwd = true,  -- Use git root as working directory

      -- Diff integration
      diff = {
        auto_close_on_accept = true,
        vertical_split = true,
        open_in_current_tab = true,
        keep_terminal_focus = true,
      },

      -- Behavior
      focus_after_send = false,
    },
    keys = {
      { "<C-\\>", toggle_claude, mode = { "n", "i", "v", "t" }, desc = "Toggle Claude Code" },
      { "<leader>ac", toggle_claude, desc = "Toggle Claude Code" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = { "n", "v" }, desc = "Send to Claude" },
      -- Right-side shell terminal, mutually exclusive with Claude Code.
      { "<C-S-\\>", toggle_right_term, mode = { "n", "i", "v", "t" }, desc = "Toggle right-side terminal (exclusive with Claude)" },
    },
  },

}
