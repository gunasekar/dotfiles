-- Safe buffer removal that preserves window layout
-- Part of mini.nvim ecosystem: https://github.com/echasnovski/mini.nvim
return {
  "echasnovski/mini.bufremove",
  version = false,
  config = function()
    require("mini.bufremove").setup({
      -- Set to true to disable "Buffer X deleted" messages
      silent = false,
    })
  end,
}
