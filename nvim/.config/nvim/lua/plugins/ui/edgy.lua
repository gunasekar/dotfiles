-- Panel layout manager: pins neo-tree (left), terminals (bottom/right) into
-- stable slots so Neovim's window equalization never steals their dimensions.
-- Both bottom and right slots share ft = "snacks_terminal", so filters on the
-- buffer name discriminate them: agent/claude/cursor-agent go right,
-- plain shell goes bottom. Buffer names look like: term://...//<pid>:/path/to/cmd
local function is_right_terminal(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name:find("claude", 1, true) ~= nil
      or name:find("cursor-agent", 1, true) ~= nil
      or name:find(".local/bin/agent", 1, true) ~= nil
end

local function is_float_terminal(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name:find("btop", 1, true) ~= nil
      or name:find("htop", 1, true) ~= nil
end


return {
  "folke/edgy.nvim",
  event = "VeryLazy",
  opts = {
    animate = { enabled = false },

    left = {
      {
        ft = "neo-tree",
        size = { width = 30 },
        pinned = true,  -- reserve the slot even when neo-tree is toggled off
        open = "Neotree",
      },
    },

    bottom = {
      {
        ft = "snacks_terminal",
        size = { height = 20 },
        wo = { winbar = false },
        filter = function(buf, _win)
          return not is_right_terminal(buf) and not is_float_terminal(buf)
        end,
      },
    },

    right = {
      -- Claude Code and Cursor share this slot. The mutual-exclusion logic in
      -- agents.lua keeps them alternating, so only one is visible at a time.
      {
        ft = "snacks_terminal",
        size = { width = 0.4 },
        wo = { winbar = false },
        filter = function(buf, _win)
          return is_right_terminal(buf)
        end,
      },
    },

    -- Applied to every edgy-managed window
    wo = {
      winfixwidth    = true,
      winfixheight   = true,
      spell          = false,
      signcolumn     = "no",
      number         = false,
      relativenumber = false,
      winhighlight   = "Normal:NeoTreeNormal,NormalNC:NeoTreeNormalNC",
    },

    exit_when_last = false,
  },

  keys = {
    {
      "<leader>up",
      function()
        -- agents.lua is key-lazy-loaded, so force it in before listing
        -- sessions or its manager may not have registered yet.
        require("lazy").load({ plugins = { "claudecode.nvim" } })
        require("util.term_sessions").picker()
      end,
      desc = "Pick panel/session",
    },
    { "<leader>uP", function() require("edgy").goto_main() end, desc = "Focus editor (Edgy)" },
  },
}
