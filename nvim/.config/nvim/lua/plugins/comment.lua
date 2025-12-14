-- Comment.nvim - Smart and powerful commenting
return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  config = function()
    require("Comment").setup({
      -- Add a space between comment and the line
      padding = true,
      -- Whether the cursor should stay at its position
      sticky = true,
      -- Lines to be ignored while (un)comment
      ignore = "^$",
      -- LHS of toggle mappings in NORMAL mode
      toggler = {
        line = "gcc", -- Line-comment toggle
        block = "gbc", -- Block-comment toggle
      },
      -- LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = {
        line = "gc", -- Line-comment operator
        block = "gb", -- Block-comment operator
      },
      -- LHS of extra mappings
      extra = {
        above = "gcO", -- Add comment on the line above
        below = "gco", -- Add comment on the line below
        eol = "gcA", -- Add comment at the end of line
      },
      -- Enable keybindings
      mappings = {
        basic = true,
        extra = true,
      },
      -- Function to call before (un)comment
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    })
  end,
}
