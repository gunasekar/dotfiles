-- Code formatting with conform.nvim
-- Unified formatter for all filetypes with automatic format-on-save
-- Falls back to LSP formatting when no dedicated formatter is available
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    -- Primary format keybinding (replaces LSP format)
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
    -- Alternative format keybinding
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer (alt)",
    },
  },
  opts = {
    -- Format on save with LSP fallback for unsupported filetypes
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
    -- Formatters by filetype
    -- Each formatter runs in sequence (e.g., goimports then gofmt for Go)
    formatters_by_ft = {
      -- Systems programming
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      rust = { "rustfmt" },

      -- Python
      python = { "black", "isort" },

      -- Web: JavaScript/TypeScript
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      vue = { "prettier" },

      -- Web: Markup & Styling
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      less = { "prettier" },

      -- Data formats
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      toml = { "taplo" },
      graphql = { "prettier" },

      -- Documentation
      markdown = { "prettier" },

      -- Shell scripts
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
    },
  },
}
