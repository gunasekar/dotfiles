-- Comprehensive health check for the entire Neovim configuration
local M = {}

function M.check_all()
  print("═══════════════════════════════════")
  print("      NEOVIM CONFIGURATION HEALTH   ")
  print("═══════════════════════════════════")
  print("")

  -- Check Mason tools
  print("🔧 MASON TOOLS:")
  local ok, mason_verify = pcall(require, "config.mason-verify")
  if ok then
    mason_verify.verify_tools()
  else
    print("  ⚠ mason-verify.lua not loaded")
  end
  print("")

  -- Check LSP status
  print("󰒋 LSP STATUS:")
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients > 0 then
    for _, client in ipairs(clients) do
      print("  ✓ " .. client.name .. " (ID: " .. client.id .. ")")
    end
  else
    print("  ⚠ No LSP clients attached to current buffer")
    print("  💡 Try opening a code file or run :LspInfo")
  end
  print("")

  -- Check formatters
  print("󰉿 FORMATTERS:")
  local ok, conform = pcall(require, "conform")
  if ok then
    local formatters = conform.list_formatters_to_run(0)
    if #formatters > 0 then
      for _, formatter in ipairs(formatters) do
        print("  ✓ " .. formatter.name)
      end
    else
      print("  ⚠ No formatters available for " .. vim.bo.filetype)
    end
  else
    print("  ✗ Conform.nvim not loaded")
  end
  print("")

  -- Check linters
  print("󰁨 LINTERS:")
  local ok, lint = pcall(require, "lint")
  if ok then
    local linters = lint.linters_by_ft[vim.bo.filetype] or {}
    if #linters > 0 then
      for _, linter in ipairs(linters) do
        print("  ✓ " .. linter)
      end
    else
      print("  ⚠ No linters configured for " .. vim.bo.filetype)
    end
  else
    print("  ✗ nvim-lint not loaded")
  end
  print("")

  -- Check key plugins
  print("📦 KEY PLUGINS:")
  local plugins_to_check = {
    { name = "mason", module = "mason" },
    { name = "conform", module = "conform" },
    { name = "lint", module = "lint" },
    { name = "trouble", module = "trouble" },
    { name = "dap", module = "dap" },
    { name = "treesitter", module = "nvim-treesitter" },
    { name = "telescope", module = "telescope" },
    { name = "gitsigns", module = "gitsigns" },
    { name = "blink.cmp", module = "blink.cmp" },
  }

  for _, plugin in ipairs(plugins_to_check) do
    local ok, _ = pcall(require, plugin.module)
    if ok then
      print("  ✓ " .. plugin.name)
    else
      print("  ✗ " .. plugin.name .. " (not loaded)")
    end
  end
  print("")

  -- Summary
  print("═══════════════════════════════════")
  print("💡 TIPS:")
  print("  • Run :checkhealth for detailed Neovim health")
  print("  • Run :MasonVerify for Mason tool verification")
  print("  • Run :Mason to install missing tools")
  print("  • Run :Lazy sync to update plugins")
  print("═══════════════════════════════════")
end

-- Create user command
vim.api.nvim_create_user_command("HealthCheck", M.check_all, { desc = "Run comprehensive configuration health check" })

return M
