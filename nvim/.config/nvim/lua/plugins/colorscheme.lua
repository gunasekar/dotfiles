-- Colorscheme Options
-- Set enabled = true for the theme you want to use
-- All configurations based on official documentation (as of 2025-12-14)

return {
  -- Gruvbox (Retro groove warm theme)
  -- Repo: https://github.com/ellisonleao/gruvbox.nvim
  -- Requires: Neovim 0.8.0+
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    enabled = true,
    opts = {
      terminal_colors = true,
      undercurl = true,
      underline = true,
      bold = false,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      invert_selection = false,
      invert_signs = false,
      invert_tabline = false,
      inverse = true,
      contrast = "hard", -- Options: "hard", "soft", or ""
      palette_overrides = {
        dark0_hard = "#000000",  -- Main background
        dark0 = "#000000",       -- Default dark background
        dark0_soft = "#000000",  -- Soft contrast background
      },
      overrides = {},
      dim_inactive = false,
      transparent_mode = false,
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      pcall(vim.cmd, "colorscheme gruvbox")
    end,
  },
}
