-- Status line
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      component_separators = { left = "|", right = "|" },
      section_separators = { left = "", right = "" },
      globalstatus = true,
      refresh = {
        statusline = 100,
        tabline = 100,
        winbar = 100,
      },
    },
    -- Disable tabline since we're using bufferline
    tabline = {},
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = {
        {
          "filename",
          path = 1,
          symbols = {
            modified = "[+]",
            readonly = "[-]",
            unnamed = "[No Name]",
          },
        }
      },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    extensions = { "neo-tree", "lazy", "mason" },
    -- Disable winbar completely to let neo-tree show its source selector tabs
    winbar = {},
    inactive_winbar = {},
  },
}
