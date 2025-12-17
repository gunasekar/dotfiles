-- Which-key.nvim - Displays a popup with possible keybindings
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Document existing key chains using v3 API
    wk.add({
      { "<leader>a", group = "AI Assistant" },
      { "<leader>b", group = "Buffer" },
      { "<leader>c", group = "Code" },
      { "<leader>d", group = "Debug" },
      { "<leader>f", group = "Find/File" },
      { "<leader>g", group = "Git" },
      { "<leader>h", group = "Hunk (Git)" },
      { "<leader>l", group = "LSP/Lint" },
      { "<leader>n", group = "Notifications" },
      { "<leader>s", group = "Search" },
      { "<leader>S", group = "Search & Replace" },
      { "<leader>t", group = "Toggle/Terminal" },
      { "<leader>T", group = "TypeScript Tools" },
      { "<leader>u", group = "UI/Toggle" },
      { "<leader>x", group = "Trouble/Quickfix" },
    })
  end,
}
