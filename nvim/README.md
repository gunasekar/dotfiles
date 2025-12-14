# Neovim Development Environment

A modern Neovim configuration for programming with LSP, Git integration, and AI assistance.

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

### Optional: Claude AI Setup
Add to your `~/.zshrc`:
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```
Get your API key from: https://console.anthropic.com/

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
Tab / Shift-Tab Next/previous buffer (bufferline)
<Space>1-9      Jump to buffer 1-9
[b / ]b         Previous/next buffer
<Space>bd       Delete buffer
```

### Harpoon (Working Set Navigation)
```
<Space>a    Mark current file (add to working set)
Ctrl-e      Toggle Harpoon menu
<Space>1-4  Jump to marked files 1-4
```
**Workflow:** Mark 2-4 files you're actively editing for instant switching.

### Editing
```
gcc         Comment/uncomment line
gc (visual) Comment selection
dd          Delete line
yy          Copy line
p           Paste
ciw         Change word
di"         Delete inside quotes
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
<Space>gp   Preview change
<Space>gs   Stage hunk
<Space>gb   Blame line
```

### AI Assistant (Avante)
```
<Space>aa   Open Claude chat
```
In chat:
- Select code → `<Space>aa` → Ask questions
- `a` Apply suggestion
- `A` Apply all suggestions

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
<Space>gp       Preview what changed
<Space>gs       Stage this change
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
<Space>eb       Open buffers view
<Space>eg       Open git status view
Inside explorer:
  < / >         Switch between Filesystem/Buffers/Git tabs
  j/k           Navigate
  Enter         Open file/folder
  s             Open in vertical split
  S             Open in horizontal split
  a             New file
  A             New directory
  d             Delete
  r             Rename
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

Add more in `lua/plugins/lsp.lua`

## Features

- **LSP**: Code completion, diagnostics, formatting (15 language servers)
- **Treesitter**: Advanced syntax highlighting
- **Bufferline**: Visual tab bar showing all open buffers with safe deletion (mini.bufremove)
- **Git**: Visual indicators, staging, blame, diff (Lazygit + Gitsigns)
- **AI**: Claude integration for code assistance (Avante)
- **Harpoon**: Fast navigation between working files (2-4 files)
- **Telescope**: Fuzzy finder for files, buffers, and text search
- **Which-key**: Press `<Space>` to see available commands
- **Neo-tree**: Modern file explorer with Filesystem/Buffers/Git views (nvim-tree available as backup)

## Buffer Navigation Philosophy

This setup provides **multiple navigation methods**:

- **Bufferline** (top tabs): Visual overview of all open buffers
  - Navigate with `Tab`/`Shift-Tab` or `<Space>1-9`
  - Pin frequently used buffers with `<Space>bp`
- **Harpoon** (2-4 files): Your active working set - instant jumps with `<Space>1-4`
- **Telescope** (all buffers): Fuzzy search with `<Space>,`

**Choose your style:** Visual tabs (bufferline), marked files (harpoon), or search (telescope).

## Customization

```
lua/config/options.lua       Editor settings
lua/config/keymaps.lua       Custom keybindings
lua/plugins/colorscheme.lua  Theme (OneDark Pro/Gruvbox)
lua/plugins/lsp.lua          Language servers
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
5. Select code and use `<Space>aa` to ask Claude about it

## Learn More

- Run `vimtutor` in terminal for interactive Vim tutorial
- `:help` in Neovim for built-in documentation
- Press `?` in Lazygit for Git help
- [Neovim Documentation](https://neovim.io/doc/)
