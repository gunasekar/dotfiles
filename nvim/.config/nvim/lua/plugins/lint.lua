-- nvim-lint - Asynchronous linter plugin
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Shellcheck strict mode toggle
    local shellcheck_strict = false

    -- Configure linters by filetype
    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      python = { "pylint" },
      go = { "golangcilint" },
      lua = { "luacheck" },
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      dockerfile = { "hadolint" },
      yaml = { "yamllint" },
      json = { "jsonlint" },
      markdown = { "markdownlint" },
      -- Add more as needed
    }

    -- Create autocommand to trigger linting
    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    -- Auto-lint only on save (not on BufEnter or InsertLeave)
    -- For manual linting, use <leader>ll
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- Manual lint trigger keymap
    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })

    -- Toggle shellcheck strict mode (enables all style checks)
    vim.keymap.set("n", "<leader>ls", function()
      shellcheck_strict = not shellcheck_strict

      -- Configure shellcheck args based on strict mode
      if shellcheck_strict then
        -- Enable all checks (override .shellcheckrc disables)
        lint.linters.shellcheck.args = {
          "--format=json",
          "--enable=all",
          "--shell=bash",
          "-",
        }
        print("Shellcheck STRICT mode enabled (all checks)")
      else
        -- Use default config from .shellcheckrc
        lint.linters.shellcheck.args = {
          "--format=json",
          "-",
        }
        print("Shellcheck NORMAL mode (using .shellcheckrc)")
      end

      -- Re-run linting with new settings
      lint.try_lint()
    end, { desc = "Toggle shellcheck strict mode" })
  end,
}
