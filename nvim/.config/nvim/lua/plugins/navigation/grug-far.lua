-- grug-far.nvim - Find and replace with ripgrep
return {
  "MagicDuck/grug-far.nvim",
  keys = {
    {
      "<leader>Sr",
      function()
        require("grug-far").open()
      end,
      desc = "Search & Replace (grug-far)",
    },
    {
      "<leader>Sw",
      function()
        require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
      end,
      desc = "Search & Replace current word",
    },
    {
      "<leader>Sf",
      function()
        require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
      end,
      desc = "Search & Replace in current file",
    },
    {
      "<leader>Sv",
      function()
        require("grug-far").with_visual_selection()
      end,
      mode = { "v" },
      desc = "Search & Replace visual selection",
    },
  },
  config = function()
    require("grug-far").setup({
      -- Use vertical split like spectre
      windowCreationCommand = "vnew",
      -- Automatic search on leaving insert mode (similar to spectre behavior)
      searchOnInsertLeave = true,
    })
  end,
}
