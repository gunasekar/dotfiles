-- File and folder icons
return {
  "nvim-tree/nvim-web-devicons",
  lazy = false,
  priority = 1000,
  config = function()
    require("nvim-web-devicons").setup({
      default = true,
      strict = true,
      variant = "dark",
      override = {},
      override_by_filename = {},
      override_by_extension = {},
    })
  end,
}
