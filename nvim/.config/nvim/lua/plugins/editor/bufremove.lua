-- Safe buffer deletion that preserves window layout
return {
  "echasnovski/mini.bufremove",
  version = false,
  keys = {
    { "<leader>bd", function() require("mini.bufremove").delete(0, false) end, desc = "Delete buffer" },
    { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete buffer (force)" },
  },
  config = function()
    require("mini.bufremove").setup({
      silent = false,
    })
  end,
}
