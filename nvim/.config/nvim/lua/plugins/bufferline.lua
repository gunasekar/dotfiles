-- Buffer tab line - shows all open buffers as tabs
return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "echasnovski/mini.bufremove",
  },
  event = "VeryLazy",
  config = function()
    local bufferline = require("bufferline")

    bufferline.setup({
      -- Theme-aware highlights that adapt to any colorscheme
      -- Uses existing highlight groups instead of hardcoded colors
      highlights = {
        separator = {
          fg = { attribute = "fg", highlight = "Comment" }, -- Uses theme's comment color
        },
        separator_selected = {
          fg = { attribute = "fg", highlight = "Function" }, -- Uses theme's function/keyword color
        },
        separator_visible = {
          fg = { attribute = "fg", highlight = "Comment" }, -- Uses theme's comment color
        },
      },
      options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        style_preset = bufferline.style_preset.default,
        themable = true,
        numbers = function(opts)
          -- Show number of modified buffers in each tab
          return string.format("%s", opts.raise(opts.ordinal))
        end,
        -- Use mini.bufremove for safe buffer deletion that preserves window layout
        -- Reference: https://github.com/echasnovski/mini.nvim/blob/main/doc/mini-bufremove.txt
        close_command = function(bufnum)
          require("mini.bufremove").delete(bufnum, false)
        end,
        right_mouse_command = function(bufnum)
          require("mini.bufremove").delete(bufnum, false)
        end,
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
          icon = "▎",
          style = "icon",
        },
        buffer_close_icon = "󰅖",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        max_name_length = 18,
        max_prefix_length = 15,
        truncate_names = true,
        tab_size = 20,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Explorer",
            text_align = "center",
            separator = true,
          },
        },
        -- Exclude neo-tree and other special buffers from the list
        custom_filter = function(buf_number, buf_numbers)
          -- Filter out neo-tree buffers
          local buftype = vim.bo[buf_number].buftype
          local filetype = vim.bo[buf_number].filetype

          if filetype == "neo-tree" or buftype == "nofile" or buftype == "terminal" then
            return false
          end

          return true
        end,
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        show_tab_indicators = true,
        show_duplicate_prefix = true,
        persist_buffer_sort = true,
        move_wraps_at_ends = false,
        separator_style = "thin", -- Default and most widely used style. Options: "thin" (default) | "thick" | "slant" | "padded_slant" | "slope" | "padded_slope"
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
        sort_by = "insert_after_current",
      },
    })

    -- Keymaps for buffer navigation
    local keymap = vim.keymap
    keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
    keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
    keymap.set("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Toggle buffer pin" })
    keymap.set("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<CR>", { desc = "Delete non-pinned buffers" })
    keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close other buffers" })
    keymap.set("n", "<leader>br", "<cmd>BufferLineCloseRight<CR>", { desc = "Close buffers to the right" })
    keymap.set("n", "<leader>bl", "<cmd>BufferLineCloseLeft<CR>", { desc = "Close buffers to the left" })
    keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

    -- Navigate to specific buffer by number
    for i = 1, 9 do
      keymap.set("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", { desc = "Go to buffer " .. i })
    end
  end,
}
