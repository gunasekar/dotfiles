# Neovim Development Environment

A modern Neovim configuration for programming with LSP, Git integration, and AI assistance.

## Review Docs

- [Review flow](REVIEW_FLOW.md): forum-ready checklist for auditing and sharing the configuration.
- [Quick reference](QUICK_REFERENCE.md): setup, health checks, plugin map, and troubleshooting.

## Quick Setup

### Prerequisites
```bash
# Install Neovim and dependencies
brew install neovim ripgrep fd node

# Install Python provider (optional)
pip3 install pynvim
```

### Installation
```bash
# 1. Stow the configuration
cd ~/.dotfiles
stow nvim

# 2. Launch Neovim (plugins install automatically)
nvim

# 3. Verify installation
:checkhealth
:Mason
```

### Optional: HTTP AI Setup
Claude Code CLI does not need an API key in this repo. If you later configure a
direct HTTP adapter, keep credentials in a private local shell file or
password-manager-backed loader, not directly in this repo.

Claude Code CLI usage is managed through the terminal integration below, which
keeps sessions compatible with the standalone `claude` CLI.

## Essential Keybindings

**Leader key:** `Space`

### Survival Basics
```
i           Enter insert mode (start typing)
Esc         Normal mode (navigation)
:w          Save file
:q          Quit
:wq         Save and quit
u           Undo
Ctrl-r      Redo
```

### File & Navigation
```
<Space>e    Toggle file explorer
<Space>ff   Find files
<Space>fg   Search in files (grep)
<Space>,    Quick buffer switcher
<Space>fr   Recent files

Ctrl-h/j/k/l    Navigate between windows
Tab / Shift-Tab Next/previous buffer
[b / ]b         Previous/next buffer
<Space>1-9      Jump to buffer 1-9 (numbers shown in Neo-tree and the winbar)
<Space>,        Fuzzy buffer switcher (Telescope)
<Space>bd       Delete buffer
<Space>bo       Close other buffers
```

### Editing
```
gcc         Comment/uncomment line
gc (visual) Comment selection
dd          Delete line
yy          Copy line
p           Paste
ciw         Change word
di"         Delete inside quotes
Yp          Copy absolute file path
Yr          Copy relative file path
Yf          Copy filename only
```

### LSP (Code Intelligence)
```
gd          Go to definition
gr          Show references
K           Show documentation
<Space>rn   Rename symbol
<Space>ca   Code actions
<Space>f    Format code
```

### Git Integration
```
<Space>gg   Open Lazygit (visual Git UI)
]c          Next change
[c          Previous change
<Space>hp   Preview hunk
<Space>hs   Stage hunk
<Space>hb   Blame line
```

### AI Agent
```
<C-\>       Toggle right panel (current agent session, normal/insert/visual/terminal)
<C-S-\>     Open new agent session (fzf picker: claude, plan, explore, cursor-agent)
<C-S-]>     Next agent session (all modes)
<C-S-[>     Previous agent session (all modes)
<Space>ac   Toggle right panel
<Space>as   Send selection/buffer to the active agent (normal/visual)
<Space>a]   Next agent session
<Space>a[   Previous agent session
```

In the agent terminal:
- `<Esc>` leaves terminal mode (back to Neovim normal)
- `<C-Esc>` interrupts the agent (cancels the current prompt)

## Git Workflow with Lazygit

### Open Lazygit
```
<Space>gg
```

### Inside Lazygit
```
j/k or ↑/↓      Navigate
Space           Stage/unstage file
a               Stage all
c               Commit
P               Push
p               Pull
d               View diff
?               Show help
q               Quit
```

### Common Git Tasks

**Review changes:**
```
1. <Space>gg
2. Navigate files with j/k
3. Press Enter to see diff
```

**Commit workflow:**
```
1. <Space>gg
2. Stage files with Space or 'a' for all
3. Press 'c' to commit
4. Type message, save and quit
5. Press 'P' to push
```

**Quick inline review:**
```
]c              Jump to next change
<Space>hp       Preview what changed
<Space>hs       Stage this change
```

## Neovim Basics

### Modes
- **Normal mode** (Esc): Navigate and run commands
- **Insert mode** (i): Type text
- **Visual mode** (v): Select text
- **Command mode** (:): Run ex commands

### Movement (Normal mode)
```
h/j/k/l         Left/down/up/right
w/b             Next/previous word
0/$             Start/end of line
gg/G            Top/bottom of file
Ctrl-d/u        Scroll down/up
```

### Essential Commands
```
/text           Search forward
n/N             Next/previous match
*               Search word under cursor
:%s/old/new/g   Replace all
:42             Go to line 42
.               Repeat last command
```

### File Explorer (Neo-tree)
```
<Space>e        Toggle explorer
<Space>ef       Reveal current file in explorer
Inside explorer:
  j/k           Navigate
  Enter         Open file/folder
  s             Open in vertical split
  S             Open in horizontal split
  a             New file
  A             New directory
  d             Delete
  r             Rename
  Yp            Copy absolute file path
  Yr            Copy relative file path
  Yf            Copy filename only
  H             Toggle hidden files
  ?             Show help
  q             Close
```

### Telescope (Fuzzy Finder)
```
<Space>ff       Find files
<Space>fg       Search in files
Inside Telescope:
  Type to search
  Ctrl-j/k      Navigate results
  Enter         Select
  Esc           Cancel
```

## Language Support

Configured language servers (auto-install via Mason):
- **Lua** (lua_ls)
- **TypeScript/JavaScript** (ts_ls)
- **Python** (pyright)
- **Go** (gopls)
- **Rust** (rust_analyzer)
- **Bash** (bashls)
- **JSON** (jsonls)
- **YAML** (yamlls)
- **Java** (jdtls)
- **Terraform/HCL** (terraformls)
- **SQL** (sqlls)
- **Dockerfile** (dockerls)
- **Docker Compose** (docker_compose_language_service)
- **GraphQL** (graphql)
- **XML** (lemminx)

Add more in `lua/plugins/lsp/lsp.lua`

## Features

- **LSP**: Code completion, diagnostics, formatting (15 language servers)
- **Treesitter**: Advanced syntax highlighting
- **Buffers**: Numbered buffers shown in Neo-tree and the winbar; jump with `<Space>1-9`, cycle with `Tab`/`[b`/`]b`
- **Git**: Visual indicators, staging, blame, diff (Lazygit + Gitsigns)
- **AI**: Claude Code terminal integration (right-panel agent session with fzf picker)
- **Telescope**: Fuzzy finder for files, buffers, and text search
- **Which-key**: Press `<Space>` to see available commands
- **Neo-tree**: Modern file explorer with Filesystem/Buffers/Git views

## Buffer Navigation Philosophy

There is no tab bar. Each buffer gets a stable number (shown next to open files
in Neo-tree and centered in the window's winbar), and you navigate by number or
by cycling:

- **By number**: `<Space>1-9` jumps straight to that buffer.
- **By cycling**: `Tab`/`Shift-Tab` or `[b`/`]b` move to the previous/next buffer.
- **By search**: `<Space>,` opens a fuzzy buffer switcher (Telescope, MRU-sorted).
- **Closing**: `<Space>bd` deletes the current buffer, `<Space>bo` closes all others.

**Choose your style:** jump by number, cycle, or fuzzy-search.

## Customization

```
lua/config/options.lua       Editor settings
lua/config/keymaps.lua       Custom keybindings
lua/plugins/colorscheme.lua  Theme (OneDark Pro/Gruvbox)
lua/plugins/lsp/lsp.lua      Language servers
lua/plugins/quality/lint.lua Linters
lua/plugins/quality/formatters.lua Formatters
```

## Troubleshooting

**Plugins not loading:**
```vim
:Lazy sync
```

**LSP not working:**
```vim
:Mason
:LspInfo
```

**Check health:**
```vim
:checkhealth
```

**Update everything:**
```vim
:Lazy update
:Mason  (then press U)
```

## Tips

1. Press `<Space>` and wait - see all available commands (which-key)
2. Use `<Space>gg` for all Git operations - it's the easiest way
3. Use `<Space>ff` to quickly jump to any file
4. Press `K` over any function to see its documentation
5. Select code and use `<Space>as` to send it to the active Claude Code session

## Learn More

- Run `vimtutor` in terminal for interactive Vim tutorial
- `:help` in Neovim for built-in documentation
- Press `?` in Lazygit for Git help
- [Neovim Documentation](https://neovim.io/doc/)
