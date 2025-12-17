-- Dressing.nvim - Improve the default vim.ui interfaces
return {
  "stevearc/dressing.nvim",
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    input = {
      enabled = true,
      default_prompt = "Input:",
      title_pos = "left",
      insert_only = true,
      start_in_insert = true,
      border = "rounded",
      relative = "cursor",
      prefer_width = 40,
      width = nil,
      max_width = { 140, 0.9 },
      min_width = { 20, 0.2 },
    },
    select = {
      enabled = true,
      backend = { "telescope", "builtin", "nui" },
      telescope = require("telescope.themes").get_dropdown(),
    },
  },
}
