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
      bold = true,
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
      palette_overrides = {},
      overrides = {},
      dim_inactive = false,
      transparent_mode = false,
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      pcall(vim.cmd, "colorscheme gruvbox")
    end,
  },

  -- OneDark Pro (Atom's official One Dark theme)
  -- Repo: https://github.com/olimorris/onedarkpro.nvim
  -- Requires: Neovim 0.9.2+
  -- Variants: onedark, onelight, onedark_vivid, onedark_dark, vaporwave
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    enabled = false,
    opts = {
      styles = {
        types = "NONE",
        methods = "NONE",
        numbers = "NONE",
        strings = "NONE",
        comments = "italic",
        keywords = "NONE",
        constants = "NONE",
        functions = "NONE",
        operators = "NONE",
        variables = "NONE",
        parameters = "NONE",
        conditionals = "NONE",
        virtual_text = "NONE",
      },
      filetypes = {
        -- 17 languages enabled by default
        c = true,
        lua = true,
        python = true,
      },
      plugins = {
        -- 40+ plugins supported
        treesitter = true,
        telescope = true,
        nvim_lsp = true,
        nvim_cmp = true,
        gitsigns = true,
      },
      options = {
        cursorline = false,
        transparency = false,
        terminal_colors = true,
        lualine_transparency = false,
        highlight_inactive_windows = false,
      },
    },
    config = function(_, opts)
      require("onedarkpro").setup(opts)
      pcall(vim.cmd, "colorscheme onedark_dark")
    end,
  },
}
