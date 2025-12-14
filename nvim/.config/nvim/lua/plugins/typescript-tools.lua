-- TypeScript Tools - Enhanced TypeScript/JavaScript support
return {
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  opts = {
    on_attach = function(client, bufnr)
      -- Disable ts_ls if it's running (typescript-tools replaces it)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false

      local opts = { buffer = bufnr, silent = true }

      -- Keymaps
      vim.keymap.set("n", "<leader>To", "<cmd>TSToolsOrganizeImports<cr>", vim.tbl_extend("force", opts, { desc = "TS: Organize Imports" }))
      vim.keymap.set("n", "<leader>Ts", "<cmd>TSToolsSortImports<cr>", vim.tbl_extend("force", opts, { desc = "TS: Sort Imports" }))
      vim.keymap.set("n", "<leader>Tu", "<cmd>TSToolsRemoveUnused<cr>", vim.tbl_extend("force", opts, { desc = "TS: Remove Unused" }))
      vim.keymap.set("n", "<leader>Td", "<cmd>TSToolsGoToSourceDefinition<cr>", vim.tbl_extend("force", opts, { desc = "TS: Go to Source Definition" }))
      vim.keymap.set("n", "<leader>Ti", "<cmd>TSToolsAddMissingImports<cr>", vim.tbl_extend("force", opts, { desc = "TS: Add Missing Imports" }))
      vim.keymap.set("n", "<leader>Tf", "<cmd>TSToolsFixAll<cr>", vim.tbl_extend("force", opts, { desc = "TS: Fix All" }))
      vim.keymap.set("n", "<leader>Tr", "<cmd>TSToolsRenameFile<cr>", vim.tbl_extend("force", opts, { desc = "TS: Rename File" }))
      vim.keymap.set("n", "<leader>TR", "<cmd>TSToolsFileReferences<cr>", vim.tbl_extend("force", opts, { desc = "TS: File References" }))
    end,
    settings = {
      separate_diagnostic_server = true,
      publish_diagnostic_on = "insert_leave",
      -- Specify the tsserver binary (optional, uses bundled version by default)
      tsserver_path = nil,
      -- Specify tsserver plugins to load
      tsserver_plugins = {},
      -- Specify additional tsserver settings
      tsserver_max_memory = "auto",
      tsserver_format_options = {},
      tsserver_file_preferences = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
      -- Code lens settings
      code_lens = "off",
      -- Disable built-in formatting (use prettier or other formatters instead)
      disable_formatting = false,
      include_completions_with_insert_text = true,
      -- Specify the code actions to expose
      expose_as_code_action = {},
    },
  },
}
