-- Fidget - LSP progress notifications
return {
  "j-hui/fidget.nvim",
  event = "LspAttach",
  opts = {
    notification = {
      window = {
        winblend = 0,
        border = "none",
      },
    },
    progress = {
      display = {
        render_limit = 5,
        done_ttl = 3,
      },
    },
  },
}
