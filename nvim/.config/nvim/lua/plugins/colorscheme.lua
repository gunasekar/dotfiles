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
    enabled = false,
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

  -- Kanagawa (Inspired by the Great Wave off Kanagawa)
  -- Repo: https://github.com/rebelot/kanagawa.nvim
  -- Requires: Neovim 0.8.0+
  -- Variants: wave (default warm), dragon (late night), lotus (light)
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    enabled = false,
    opts = {
      compile = false,
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = false,
      dimInactive = false,
      terminalColors = true,
      colors = {
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      overrides = function(colors)
        return {}
      end,
      theme = "dragon", -- Options: "wave", "dragon", "lotus"
      background = {
        dark = "dragon",
        light = "lotus",
      },
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      pcall(vim.cmd, "colorscheme kanagawa")
    end,
  },

  -- OneDark Pro (Atom's official One Dark theme)
  -- Repo: https://github.com/olimorris/onedarkpro.nvim
  -- Requires: Neovim 0.9.2+
  -- Variants: onedark, onelight, onedark_vivid, onedark_dark, vaporwave
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    enabled = true,
    opts = {
      -- Minimal color palette with warm amber accents and white variations
      colors = {
        onedark_dark = {
          red = "#e8e4db",       -- warm off-white
          orange = "#e5b567",    -- warm honey amber
          yellow = "#d4a574",    -- muted gold
          green = "#89b482",     -- forest sage green
          cyan = "#7fb8a8",      -- aqua teal
          blue = "#e5b567",      -- warm honey amber (same as orange)
          purple = "#e8e4db",    -- warm off-white (same as red)
          white = "#eeeff2",     -- bright white
          gray = "#5c6370",      -- muted grey for comments
        },
      },
      styles = {
        types = "italic",           -- Italicize type definitions
        methods = "NONE",            -- Keep methods clean
        numbers = "NONE",            -- Keep numbers clean
        strings = "NONE",            -- Keep strings clean
        comments = "italic",         -- Italicize comments for distinction
        keywords = "NONE",           -- Keep keywords clean
        constants = "italic",        -- Italicize constants for subtle emphasis
        functions = "NONE",          -- Keep functions clean
        operators = "NONE",          -- Keep operators clean
        variables = "NONE",          -- Keep variables clean
        parameters = "NONE",         -- Keep parameters clean
        conditionals = "bold",       -- Bold conditionals for control flow emphasis
        virtual_text = "italic",     -- Italicize virtual text (diagnostics/hints)
      },
      -- Enable theme integration for all supported filetypes and plugins.
      -- You can later disable specific ones with `filetypes = { all = true, markdown = false }` etc.
      filetypes = { all = true },
      plugins = { all = true },
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
