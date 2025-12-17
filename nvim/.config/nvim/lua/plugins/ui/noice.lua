-- Noice: Better UI for messages, cmdline and popupmenu
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("noice").setup({
      cmdline = {
        enabled = true,
        view = "cmdline", -- Use classic cmdline at bottom instead of popup
      },
      lsp = {
        -- Override markdown rendering for better LSP documentation
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        hover = {
          silent = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = false, -- Use classic bottom cmdline instead of popup
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            kind = "",
            find = "written",
          },
          opts = { skip = true },
        },
      },
    })
  end,
}
