-- One Dark colorscheme (matching Zed editor theme)
-- Repo: https://github.com/navarasu/onedark.nvim

return {
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    config = function()
      require("onedark").setup({
        style = "dark",
        transparent = false,
        term_colors = true,
        ending_tildes = false,
        code_style = {
          comments = "italic",
          keywords = "none",
          functions = "none",
          strings = "none",
          variables = "none",
        },
        colors = {
          bg0 = "#000000",
          bg1 = "#111111",
          bg2 = "#1a1a1a",
          bg3 = "#222222",
          bg_d = "#000000",
          grey = "#777777",
        },
        highlights = {
          WinSeparator = { fg = "#333333" },
          NeoTreeWinSeparator = { fg = "#333333", bg = "#000000" },
          NeoTreeNormal = { bg = "#000000" },
          NeoTreeNormalNC = { bg = "#000000" },
          NormalFloat = { bg = "#0a0a0a" },
          FloatBorder = { fg = "#333333", bg = "#0a0a0a" },
          CursorLine = { bg = "#111111" },
          StatusLine = { bg = "#000000" },
          TabLine = { bg = "#000000" },
          TabLineFill = { bg = "#000000" },
          Search = { bg = "#3a3a00" },
        },
        diagnostics = {
          darker = true,
          undercurl = true,
          background = true,
        },
      })
      require("onedark").load()
    end,
  },
}
