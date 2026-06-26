-- Mason verification utility
local M = {}

-- Check if a tool is managed by Mason
function M.is_mason_tool(tool_name)
	local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/" .. tool_name
	return vim.fn.executable(mason_bin) == 1
end

-- Get the path of a tool
function M.get_tool_path(tool_name)
	return vim.fn.exepath(tool_name)
end

local tool_groups = {
	{
		title = "LSP SERVER EXECUTABLES",
		tools = {
			{ name = "gopls", hint = "gopls" },
			{ name = "lua-language-server", hint = "lua_ls" },
			{ name = "rust-analyzer", hint = "rust_analyzer" },
			{ name = "typescript-language-server", hint = "ts_ls" },
			{ name = "pyright-langserver", hint = "pyright" },
			{ name = "bash-language-server", hint = "bashls" },
			{ name = "vscode-json-language-server", hint = "jsonls" },
			{ name = "yaml-language-server", hint = "yamlls" },
			{ name = "jdtls", hint = "jdtls" },
			{ name = "terraform-ls", hint = "terraformls" },
			{ name = "sql-language-server", hint = "sqlls" },
			{ name = "docker-langserver", hint = "dockerls" },
			{ name = "docker-compose-langserver", hint = "docker_compose_language_service" },
			{ name = "graphql-lsp", hint = "graphql" },
			{ name = "lemminx", hint = "lemminx" },
		},
	},
	{
		title = "FORMATTER EXECUTABLES",
		tools = {
			{ name = "stylua" },
			{ name = "goimports" },
			{ name = "gofmt", expected = "toolchain" },
			{ name = "rustfmt", expected = "toolchain" },
			{ name = "black" },
			{ name = "isort" },
			{ name = "prettier" },
			{ name = "taplo" },
			{ name = "shfmt" },
		},
	},
	{
		title = "LINTER EXECUTABLES",
		tools = {
			{ name = "eslint_d" },
			{ name = "pylint" },
			{ name = "golangci-lint" },
			{ name = "luacheck" },
			{ name = "shellcheck" },
			{ name = "hadolint" },
			{ name = "yamllint" },
			{ name = "jsonlint" },
			{ name = "markdownlint" },
		},
	},
}

local function source_label(path)
	if path == "" then
		return "missing"
	end
	if path:find(vim.fn.stdpath("data") .. "/mason/bin", 1, true) then
		return "mason"
	end
	return "system"
end

local function print_path_summary()
	print("Current Neovim PATH (first 3 entries):")
	local path_entries = vim.split(vim.env.PATH or "", ":")
	for i = 1, math.min(3, #path_entries) do
		local marker = path_entries[i]:find("mason", 1, true) and "🔧" or "  "
		print(string.format("%s %d: %s", marker, i, path_entries[i]))
	end
	print("")
end

-- Check all configured tools using the executable names Neovim actually calls.
function M.verify_tools()
	print_path_summary()

	print("═══════════════════════════════════")
	print("         NVIM TOOL VERIFICATION     ")
	print("═══════════════════════════════════")

	local found = 0
	local total = 0
	local missing_tools = {}

	for _, group in ipairs(tool_groups) do
		print("\n" .. group.title .. ":")

		for _, tool in ipairs(group.tools) do
			total = total + 1
			local path = M.get_tool_path(tool.name)
			local source = source_label(path)
			local hint = tool.hint and (" (" .. tool.hint .. ")") or ""
			local expected = tool.expected and (" expected:" .. tool.expected) or ""

			if source == "missing" then
				print(string.format("%-34s ❌ NOT FOUND%s", tool.name .. hint, expected))
				table.insert(missing_tools, tool.name)
			else
				found = found + 1
				local status = source == "mason" and "✅ MASON" or "✅ SYSTEM"
				print(string.format("%-34s %s%s", tool.name .. hint, status, expected))
				print(string.format("  └─ %s", path))
			end
		end
	end

	print("\n═══════════════════════════════════")
	print(string.format("Available tools: %d/%d", found, total))

	if #missing_tools > 0 then
		print("\n⚠️  MISSING EXECUTABLES:")
		for _, tool in ipairs(missing_tools) do
			print("  • " .. tool)
		end
		print(
			"\n💡 Install with Mason, Homebrew, language toolchains, or project-local package managers as appropriate."
		)
	else
		print("🎉 All configured tool executables are available!")
	end
end

-- Function to fix PATH manually
function M.fix_path()
	local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
	local current_path = vim.env.PATH or ""

	-- Remove any existing Mason bin entries to prevent duplicates
	local path_entries = vim.split(current_path, ":")
	local clean_path_entries = {}
	local mason_found = false

	for _, entry in ipairs(path_entries) do
		if entry == mason_bin then
			mason_found = true
		else
			table.insert(clean_path_entries, entry)
		end
	end

	-- Add Mason bin directory at the beginning
	local new_path = mason_bin .. ":" .. table.concat(clean_path_entries, ":")
	vim.env.PATH = new_path

	if mason_found then
		print("🔄 Cleaned duplicate Mason entries from PATH")
	else
		print("✅ Added Mason bin to PATH: " .. mason_bin)
	end

	-- Note: Neovim will automatically refresh executable paths
	print("🔄 PATH updated - executable paths will refresh automatically")
end

-- Create commands
vim.api.nvim_create_user_command("MasonVerify", M.verify_tools, { desc = "Verify Mason tool management" })
vim.api.nvim_create_user_command("MasonFixPath", M.fix_path, { desc = "Fix Mason PATH manually" })

return M
