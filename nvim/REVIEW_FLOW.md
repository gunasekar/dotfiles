# Neovim Configuration Review Flow

This document is a shareable review flow for this Neovim setup. It is written
for Neovim users who want to audit, learn from, or adapt the configuration
without copying private assumptions blindly.

## Review Goals

- Keep the setup understandable: every plugin should have a clear owner file and
  purpose.
- Keep the setup portable: separate Neovim config, Mason-managed tools,
  Homebrew tools, Python tools, and project-local tools.
- Keep upgrades safe: prefer current Neovim and plugin APIs, and record
  intentional exceptions.
- Keep forum sharing safe: call out personal commands, forks, fonts, terminals,
  and platform assumptions.

## Architecture Map

```text
nvim/.config/nvim/
|-- init.lua
|-- lazy-lock.json
`-- lua/
    |-- config/
    |   |-- options.lua
    |   |-- keymaps.lua
    |   |-- autocmds.lua
    |   |-- lazy.lua
    |   |-- health-check.lua
    |   `-- mason-verify.lua
    `-- plugins/
        |-- assistant.lua
        |-- colorscheme.lua
        |-- csv.lua
        |-- diagram.lua
        |-- markdown.lua
        |-- comments/
        |-- editor/
        |-- lsp/
        |-- navigation/
        |-- quality/
        `-- ui/
```

Startup flow:

```text
init.lua
  -> config.blackbox
  -> config.options
  -> config.keymaps
  -> config.autocmds
  -> config.lazy
  -> config.utils
  -> config.health-check
```

Plugin loading is centralized in `lua/config/lazy.lua` and imports these groups:

- `plugins`
- `plugins.ui`
- `plugins.comments`
- `plugins.navigation`
- `plugins.lsp`
- `plugins.editor`
- `plugins.quality`

## Plugin Groups

- Core options: `lua/config/options.lua`, `lua/config/keymaps.lua`,
  `lua/config/autocmds.lua`.
  Review leader keys, clipboard, indentation, diagnostics, terminal behavior,
  and filetype detection.
- Plugin manager: `lua/config/lazy.lua`, `lazy-lock.json`.
  Review imports, update policy, lockfile state, and lazy-loading choices.
- LSP and completion: `lua/plugins/lsp/lsp.lua`,
  `lua/plugins/lsp/completion.lua`, `lua/plugins/lsp/lazydev.lua`.
  Review Neovim LSP APIs, Mason installs, server config, and completion.
- Syntax: `lua/plugins/lsp/treesitter.lua`.
  Review parser coverage, startup cost, and `main` branch API usage.
- Quality: `lua/plugins/quality/formatters.lua`,
  `lua/plugins/quality/lint.lua`.
  Review formatter/linter coverage, save hooks, and manual commands.
- Navigation: `lua/plugins/navigation/telescope.lua`,
  `lua/plugins/navigation/neo-tree.lua`,
  `lua/plugins/navigation/which-key.lua`.
  Review finder defaults, hidden files, explorer behavior, and keymap groups.
- Editing: `lua/plugins/editor/*.lua`, `lua/plugins/comments/comment.lua`.
  Review buffer deletion, terminals, autopairs, comments, and indentation.
- Git: `lua/plugins/git.lua`.
  Review Lazygit, Diffview, and Gitsigns hunk mappings.
- UI: `lua/plugins/ui/*.lua`, `lua/plugins/colorscheme.lua`.
  Review theme, statusline, notifications, diagnostics, and icons.
- Markdown and data: `lua/plugins/markdown.lua`, `lua/plugins/diagram.lua`,
  `lua/plugins/csv.lua`.
  Review renderer trade-offs, terminal graphics requirements, and CSV behavior.
- AI assistant: `lua/plugins/assistant.lua`.
  Review local commands, terminal layout, and private workflow assumptions.

## LSP Review

This configuration targets modern Neovim LSP APIs:

- `vim.lsp.config`
- `vim.lsp.enable`
- `vim.lsp.get_clients`
- `vim.diagnostic.config`

Configured LSP servers:

| Language or format | Server |
| --- | --- |
| Lua | `lua_ls` |
| TypeScript/JavaScript | `ts_ls` |
| Python | `pyright` |
| Go | `gopls` |
| Rust | `rust_analyzer` |
| Shell | `bashls` |
| JSON | `jsonls` |
| YAML | `yamlls` |
| Java | `jdtls` |
| Terraform/HCL | `terraformls` |
| SQL | `sqlls` |
| Dockerfile | `dockerls` |
| Docker Compose | `docker_compose_language_service` |
| GraphQL | `graphql` |
| XML | `lemminx` |

Review checklist:

- Confirm every server in `ensure_installed` is also enabled with
  `vim.lsp.enable`.
- Confirm every server has sensible `cmd`, `filetypes`, and `root_markers`.
- Confirm per-language settings are intentional, especially YAML schemas,
  Java settings, Terraform validation, and XML formatting.
- Confirm completion capabilities are compatible with `blink.cmp`.
- Confirm public docs mention the minimum Neovim version expected by the config.

## Format And Lint Review

Formatters are managed through `conform.nvim` and run on save with LSP fallback.

| Filetype | Formatters |
| --- | --- |
| Lua | `stylua` |
| Go | `goimports`, `gofmt` |
| Rust | `rustfmt` |
| Python | `black`, `isort` |
| JavaScript/TypeScript/Vue | `prettier` |
| HTML/CSS/SCSS/Less | `prettier` |
| JSON/YAML/GraphQL/Markdown | `prettier` |
| TOML | `taplo` |
| Shell/Zsh | `shfmt` |

Linters are managed through `nvim-lint` and run on save.

| Filetype | Linters |
| --- | --- |
| JavaScript/TypeScript | `eslint_d` |
| Python | `pylint` |
| Go | `golangcilint` |
| Lua | `luacheck` |
| Shell/Bash | `shellcheck` |
| Dockerfile | `hadolint` |
| YAML | `yamllint` |
| JSON | `jsonlint` |
| Markdown | `markdownlint` |

Review checklist:

- Match every configured formatter/linter to an installation source.
- Keep host-level tools in `brew/.Brewfile` when they are expected globally.
- Keep Python tools in `python/requirements.txt` when they are Python packages.
- Keep JavaScript tools project-local unless the repo intentionally provides a
  global installer.
- Reconcile `config.mason-verify` whenever LSP, formatter, or linter lists
  change.

## Dependency Sources

- Mason: LSP servers and selected developer tools.
  Verify with `:Mason` and `:MasonVerify`.
- Homebrew: `neovim`, `ripgrep`, `fd`, `stylua`, `shellcheck`,
  `luacheck`, `yamllint`, `markdownlint-cli`, `hadolint`, `lazygit`,
  `prettier`, `eslint_d`, `shfmt`, `taplo`, `rust`, `graphviz`, and
  `mermaid-cli`.
  See `brew/.Brewfile`.
- Python: `pylint`, `black`, `isort`, `mypy`, `flake8`, `bandit`,
  and `pydocstyle`.
  See `python/requirements.txt`.
- Project-local Node: project-specific TypeScript, ESLint plugins, and Prettier
  plugins when needed. Avoid assuming every project uses the same JavaScript
  stack.
- Language toolchains: `gofmt` and Java tools.
  These usually come from Go, Rust, or JDK installs.

## Lazy Loading Review

Use the lazy.nvim plugin spec as the reference point.

- Prefer `opts` when a plugin supports direct `setup(opts)`.
- Use `config` when setup needs custom callbacks, keymap generation, or module
  calls that must run after the plugin is loaded.
- Use `init` only for startup globals or behavior that must happen before plugin
  load.
- Make eager plugins explicit with `lazy = false` and a short reason in code.
- Check plugins with build steps, such as `telescope-fzf-native.nvim`, for host
  dependencies like `make`.

Intentional eager or special cases in this config include:

- `snacks.nvim`: broad utility layer used by keymaps and assistant terminals.
- `neo-tree.nvim`: primary explorer and buffer-number workflow.
- `nvim-treesitter`: parser install/start behavior.
- Markdown renderer plugins: renderer behavior is intentionally documented in
  `lua/plugins/markdown.lua`.

## Keymap Review

Primary prefixes:

| Prefix | Group |
| --- | --- |
| `<leader>a` | AI assistant |
| `<leader>b` | Buffer |
| `<leader>c` | Code |
| `<leader>f` | Find/File |
| `<leader>g` | Git |
| `<leader>h` | Git hunk |
| `<leader>l` | LSP/Lint |
| `<leader>n` | Notifications |
| `<leader>s` | Search/Split |
| `<leader>t` | Toggle/Terminal |
| `<leader>u` | UI toggles |

Review checklist:

- Keep README examples in sync with actual mappings.
- Prefer `desc` on all keymaps so which-key remains useful.
- Avoid silently reusing the same mapping in unrelated plugin files.
- Public docs should distinguish Git commands (`<leader>g*`) from hunk commands
  (`<leader>h*`).

## Public Sharing Checklist

Before sharing in forums, call out these assumptions:

- The setup expects a Nerd Font for the best icon rendering.
- The terminal graphics feature for inline images/diagrams expects Ghostty,
  Kitty, or WezTerm and the Kitty graphics protocol.
- AI assistant integrations are personal workflow pieces. The command
  `claude --dangerously-skip-permissions` is intentionally local and should not
  be copied without understanding the security trade-off.
- `gunasekar/markview-smart-tables.nvim` is an open-source companion plugin for
  smart Markdown table rendering; review its README and version like any other
  external plugin.
- The repo is dotfiles-oriented and uses GNU Stow.
- Homebrew coverage is strongest on macOS; Linux users should map packages to
  their own package manager.

## Validation Flow

Run the checks from the repo root unless noted otherwise.

```bash
nvim --headless "+checkhealth" "+qa"
nvim --headless "+Lazy! sync" "+qa"
pre-commit run --all-files
shellcheck sources/*.sh
```

Inside Neovim:

```vim
:checkhealth
:Lazy
:Mason
:LspInfo
:ConformInfo
:HealthCheck
:MasonVerify
```

Use `:HealthCheck` for a quick local summary and `:MasonVerify` to check whether
expected tools are coming from Mason or the system PATH.

## Review Status

Fixed during the review pass:

- `:MasonVerify` is registered at startup and checks executable names instead of
  mixing Mason package names with runtime commands.
- `:HealthCheck` no longer reports `dap` as missing when DAP is not configured.
- `dressing.nvim` no longer requires `telescope.themes` during spec evaluation.
- LSP servers receive `blink.cmp` capabilities when `blink.cmp` is available.
- `GoToggleTest` now rejects non-Go buffers and escapes paths before editing.
- Stale bufferline-era mappings were removed from `keymaps-summary.lua`.
- The Brewfile declares the global formatter/linter executables used by Neovim:
  `prettier`, `eslint_d`, `shfmt`, `taplo`, and `rust` for `rustfmt`.
- The Neo-tree migration warning was resolved by removing the obsolete
  `enable_normal_mode_for_inputs` option.

Still needs environment or follow-up decisions:

- AI and diagram plugins have local environment assumptions that should stay
  visible before sharing the setup publicly.

## Upgrade Review

When upgrading Neovim or plugins:

1. Read the official Neovim news and help docs for the target version.
2. Read lazy.nvim release/spec docs if plugin loading behavior changes.
3. Update plugins with `:Lazy update`, then inspect `lazy-lock.json`.
4. Run the validation flow.
5. Update `README.md`, `QUICK_REFERENCE.md`, and this review flow if keymaps,
   paths, servers, tools, or assumptions changed.
