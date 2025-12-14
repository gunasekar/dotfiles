-- File and folder icons
return {
  "nvim-tree/nvim-web-devicons",
  lazy = false,
  priority = 1000,
  config = function()
    require("nvim-web-devicons").setup({
      -- globally enable default icons (default to false)
      default = true,
      -- globally enable "strict" selection of icons - icon will be looked up in
      -- different tables, first by filename, then by extension; this prevents cases when file doesn't have
      -- any extension but you still want it to have icon
      strict = true,
      -- set the light or dark variant manually (default to automatic)
      variant = "dark",
      -- override specific icons
      override = {},
      -- override by filename
      override_by_filename = {},
      -- override by extension
      override_by_extension = {},
    })
  end,
}
