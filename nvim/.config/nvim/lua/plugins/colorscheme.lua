-- Colorscheme Options
-- Set enabled = true for the theme you want to use
-- All configurations based on official documentation (as of 2025-12-14)

return {
  -- Catppuccin (Soothing pastel theme)
  -- Repo: https://github.com/catppuccin/nvim
  -- Requires: Neovim 0.8.0+
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    enabled = false,
    opts = {
      flavour = "mocha", -- Options: "latte", "frappe", "macchiato", "mocha"
      background = {
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      no_italic = false,
      no_bold = false,
      no_underline = false,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {
        mocha = {
          base = "#000000",   -- Main background (pure black)
          mantle = "#000000", -- Slightly darker than base (also pure black)
          crust = "#000000",  -- Darkest background (also pure black)
        },
      },
      custom_highlights = function(colors)
        return {
          WinSeparator = { fg = colors.surface1 },                          -- Window separator lines
          NeoTreeWinSeparator = { fg = colors.surface1, bg = colors.base }, -- Neo-tree separator
        }
      end,
      default_integrations = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      pcall(vim.cmd, "colorscheme catppuccin")
    end,
  },

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
      contrast = "soft",        -- Options: "hard", "soft", or ""
      palette_overrides = {
        dark0_hard = "#000000", -- Main background
        dark0 = "#000000",      -- Default dark background
        dark0_soft = "#000000", -- Soft contrast background
        light1 = "#F0F6FC",     -- Primary foreground (light blue-tinted white)
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
