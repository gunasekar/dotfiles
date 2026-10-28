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
| Terminals | `nvim/.config/nvim/lua/plugins/editor/snacks.lua`, `nvim/.config/nvim/lua/plugins/ui/edgy.lua` |
| AI agent | `nvim/.config/nvim/lua/plugins/agents.lua` |
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
| `O` (in Neo-tree) | Folder: open in Finder; file: Quick Look preview |
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
| `<leader>gd` | Changes diff (CodeDiff float, read-only; `q` closes) |
| `-` (in a diff) | Stage / unstage the file under the cursor |
| `S` / `U` (in a diff) | Stage all / unstage all |
| `<leader>hu` (in a diff) | Unstage hunk (`<leader>hs` stages) |
| `<leader>gh` / `<leader>gH` | History of the branch / the current file (CodeDiff, in a float) |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |
| ``<C-`>`` | Toggle bottom panel (current terminal session) |
| ``<C-S-`>`` | New terminal session (all modes) |
| `<C-S-L>` | Next terminal session (all modes) |
| `<C-S-H>` | Prev terminal session (all modes) |
| `<leader>tt` | New terminal session |
| `<leader>t]` | Next terminal session |
| `<leader>t[` | Prev terminal session |
| `<leader>up` | Pick any panel or session by name |
| `<leader>uP` | Focus main editor window |
| Drag a panel border | Resize panel (kept until nvim quits) |
| `<C-w>+` / `<C-w>-` | In a panel: grow / shrink the shell |
| `<C-w>>` / `<C-w><` | In a panel: widen / narrow a side panel |
| `<C-w>=` | In a panel: reset all panel sizes |
| `<leader>ui` | Toggle read-only rendered markdown view, diagrams included |
| `<C-\>` | Toggle right panel (current agent session) |
| `<C-S-\>` | Open new agent session |
| `<C-S-]>` | Next agent session (all modes) |
| `<C-S-[>` | Prev agent session (all modes) |
| `<leader>as` | Send context to active agent |
| `<leader>a]` | Next agent session |
| `<leader>a[` | Prev agent session |

## Panel Keys Inside tmux Under kitty

Neovim inside tmux under kitty (the trails editor) only gets most panel keys
because `kitty.conf` sends them as CSI-u and gives up its own `Ctrl+Shift`
shortcuts. Before those changes (2026-10-29) only the toggle and the leader
keys worked. Why, and what kitty sends: `tmux/README.md`, "kitty doesn't hand
tmux every key".

### Agent pane (right panel)

| Action | Key | Before | Now |
| --- | --- | --- | --- |
| Toggle panel | `<C-\>` | ✅ | ✅ |
| New agent session | `<C-S-\>` | ❌ typed `\|` | ✅ |
| Next / prev session | `<C-S-]>` / `<C-S-[>` | ❌ kitty switched splits | ✅ |
| Send context to agent | `<C-S-.>` | ❌ kitty moved the tab | ✅ |
| Interrupt the agent | `<C-Esc>` | ❌ arrived as `<Esc>` | ✅ |
| Leave terminal mode | `<Esc>` | ✅ | ✅ |
| Newline in Claude's prompt | `Shift+Enter` | ❌ submitted | ✅ |
| Leader versions | `<leader>ac` `a]` `a[` `as` | ✅ | ✅ |

### Shell pane (bottom panel)

| Action | Key | Before | Now |
| --- | --- | --- | --- |
| Toggle panel | ``<C-`>`` | ❌ typed a backtick | ✅ |
| New terminal session | ``<C-S-`>`` | ❌ kitty moved the split | ✅ |
| Next / prev session | `<C-S-L>` / `<C-S-H>` | ❌ kitty took both | ✅ |
| Leader versions | `<leader>tt` `t]` `t[` | ✅ | ✅ |

### Moving between panes

| Action | Key | Before | Now |
| --- | --- | --- | --- |
| Window left / down / up / right | `<C-h/j/k/l>` | ✅ | ✅ |
| Pick any panel or session | `<leader>up` | ✅ | ✅ |

`Ctrl+<letter>` and leader keys always came through tmux intact. With the
trail's own agent pane focused (outside Neovim), keys go to the agent, not
Neovim; there `Shift+Enter` now inserts a newline.

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
