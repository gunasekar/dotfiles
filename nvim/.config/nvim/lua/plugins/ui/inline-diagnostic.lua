-- Tiny inline diagnostic - Show diagnostics inline like VSCode
return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  config = function()
    require("tiny-inline-diagnostic").setup({
      preset = "classic",
      options = {
        show_source = false,
        throttle = 20,
        multilines = false,
        multiple_diag_under_cursor = false,
      },
    })

    -- Disable default virtual text since we're using inline diagnostics
    vim.diagnostic.config({
      virtual_text = false,
    })
  end,
}
