# Neovim Quick Reference

Short reference for installing, reviewing, and troubleshooting this Neovim
configuration.

## Setup

```bash
cd ~/.dotfiles
stow nvim
brew bundle --file=brew/.Brewfile
cd python && pip3 install --user -r requirements.txt
nvim
```

Inside Neovim, run:

```vim
:Lazy sync
:Mason
:checkhealth
```

## Core Files

| Purpose | File |
| --- | --- |
| Entry point | `nvim/.config/nvim/init.lua` |
| Options | `nvim/.config/nvim/lua/config/options.lua` |
| Keymaps | `nvim/.config/nvim/lua/config/keymaps.lua` |
| Autocmds | `nvim/.config/nvim/lua/config/autocmds.lua` |
| lazy.nvim setup | `nvim/.config/nvim/lua/config/lazy.lua` |
| Health command | `nvim/.config/nvim/lua/config/health-check.lua` |
| Mason verification | `nvim/.config/nvim/lua/config/mason-verify.lua` |
| Plugin lockfile | `nvim/.config/nvim/lazy-lock.json` |

## Plugin File Map

| Area | File or directory |
| --- | --- |
| LSP | `nvim/.config/nvim/lua/plugins/lsp/lsp.lua` |
| Completion | `nvim/.config/nvim/lua/plugins/lsp/completion.lua` |
| Treesitter | `nvim/.config/nvim/lua/plugins/lsp/treesitter.lua` |
| Formatters | `nvim/.config/nvim/lua/plugins/quality/formatters.lua` |
| Linters | `nvim/.config/nvim/lua/plugins/quality/lint.lua` |
| Explorer | `nvim/.config/nvim/lua/plugins/navigation/neo-tree.lua` |
| Fuzzy finder | `nvim/.config/nvim/lua/plugins/navigation/telescope.lua` |
| Which-key | `nvim/.config/nvim/lua/plugins/navigation/which-key.lua` |
| Git | `nvim/.config/nvim/lua/plugins/git.lua` |
| Terminals | `nvim/.config/nvim/lua/plugins/editor/toggleterm.lua` |
| AI assistant | `nvim/.config/nvim/lua/plugins/assistant.lua` |
| Markdown | `nvim/.config/nvim/lua/plugins/markdown.lua` |
| Diagrams/images | `nvim/.config/nvim/lua/plugins/diagram.lua` |
| UI | `nvim/.config/nvim/lua/plugins/ui/` |

## Health Checks

Run from the repo root:

```bash
nvim --headless "+checkhealth" "+qa"
pre-commit run --all-files
shellcheck sources/*.sh
```

Run inside Neovim:

```vim
:HealthCheck
:MasonVerify
:LspInfo
:ConformInfo
:Lazy
:Mason
```

## Keymaps

Leader key: `Space`

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle Neo-tree |
| `<leader>ef` | Reveal current file in Neo-tree |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>,` | Switch buffers |
| `<leader>bd` | Delete current buffer |
| `<leader>bo` | Close other buffers |
| `<leader>1` to `<leader>9` | Jump to numbered buffer |
| `<Tab>` / `<S-Tab>` | Next/previous buffer |
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>f` | Format buffer |
| `<leader>ll` | Lint current file |
| `<leader>ls` | Toggle ShellCheck strict mode |
| `<leader>gg` | Open Lazygit |
| `<leader>gd` | Open Diffview |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |
| ``<C-`>`` | Toggle main terminal |
| `<leader>ui` | Toggle inline images/diagrams |
| `<C-\>` | Toggle Claude Code terminal |
| `<C-S-\>` | Toggle Cursor agent terminal |

## Configured Language Servers

`lua_ls`, `ts_ls`, `pyright`, `gopls`, `rust_analyzer`, `bashls`, `jsonls`,
`yamlls`, `jdtls`, `terraformls`, `sqlls`, `dockerls`,
`docker_compose_language_service`, `graphql`, `lemminx`.

## Tool Sources

| Tool type | Source |
| --- | --- |
| Neovim, CLI tools, formatters, linters | `brew/.Brewfile` |
| Python linters/formatters | `python/requirements.txt` |
| LSP servers and selected tools | Mason |
| JavaScript/TypeScript project plugins | Project-local Node install |
| Go formatter and Java tools | Language toolchains |

## Troubleshooting

| Problem | First check |
| --- | --- |
| Plugins missing | `:Lazy sync` |
| LSP not attached | `:LspInfo`, `:Mason` |
| Formatter missing | `:ConformInfo` |
| Linter missing | `:MasonVerify`, tool executable on `PATH` |
| Icons look wrong | Install a Nerd Font and configure the terminal |
| Diagrams do not render | Use a Kitty-graphics terminal |
| Terminal keymaps differ | Confirm the terminal supports the key sequence |

For the full review checklist, see `nvim/REVIEW_FLOW.md`.
