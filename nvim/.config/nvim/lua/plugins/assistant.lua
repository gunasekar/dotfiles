-- AI Assistant integrations
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
          keys = {
            -- Override Snacks' built-in "term_normal" key (its default makes a
            -- single <Esc> pass through to the terminal and only exits on a
            -- double <Esc>). Reusing the same key name replaces that default so a
            -- single <Esc> immediately leaves terminal mode like normal Neovim,
            -- WITHOUT reaching Claude.
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
            -- <C-Esc> passes through to Claude (interrupt/cancel last prompt).
            -- Requires a terminal that distinguishes <C-Esc> from <Esc> via the
            -- kitty keyboard protocol (Ghostty + Neovim 0.11 do, by default).
            term_interrupt = {
              "<C-Esc>",
              function()
                local chan = vim.bo.channel
                if chan and chan > 0 then
                  vim.api.nvim_chan_send(chan, "\27") -- send ESC byte to Claude
                end
              end,
              mode = "t",
              desc = "Ctrl-Esc to Claude (interrupt)",
            },
          },
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
      { "<C-\\>", "<cmd>ClaudeCode<cr>", mode = { "n", "i", "v", "t" }, desc = "Toggle Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = { "n", "v" }, desc = "Send to Claude" },
    },
  },

}
