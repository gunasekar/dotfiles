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
            -- Single <Esc> passes through to Claude (interrupt/cancel).
            -- Double <Esc> exits terminal mode into Neovim normal mode.
            term_normal = {
              "<Esc><Esc>",
              function()
                vim.cmd("stopinsert")
              end,
              mode = "t",
              desc = "Double Esc to Neovim normal mode",
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
