# Neovim Developer Quick Reference

Complete cheatsheet for daily development with Neovim.

## Mode Indicators (Bottom Left)
- `-- INSERT --` = Insert mode (typing)
- `-- VISUAL --` = Visual mode (selecting)
- Nothing shown = Normal mode (navigation)

## Emergency Commands
```
Esc :q! Enter    # Force quit without saving
:qa!             # Quit all windows without saving
:wa              # Save all files
:wqa             # Save all and quit
```

## Essential Modes

### Switching Modes
| Key | Action |
|-----|--------|
| `Esc` | Normal mode (always!) |
| `i` | Insert mode (start typing) |
| `a` | Insert after cursor |
| `v` | Visual mode (select text) |
| `V` | Visual line mode |
| `Ctrl-v` | Visual block mode |
| `:` | Command mode (run commands) |

### Save and Quit
| Command | Action |
|---------|--------|
| `:w` | Save file |
| `:q` | Quit |
| `:wq` or `:x` | Save and quit |
| `:q!` | Quit without saving |
| `<Space>w` | Save (custom) |
| `<Space>q` | Quit (custom) |
| `ZZ` | Save and quit |
| `ZQ` | Quit without saving |

## Navigation (Normal Mode)

### Basic Movement
| Key | Action |
|-----|--------|
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |
| `w` | Next word |
| `b` | Previous word |
| `0` | Start of line |
| `$` | End of line |
| `gg` | Top of file |
| `G` | Bottom of file |

### Jumping Around
| Key | Action |
|-----|--------|
| `Ctrl-d` | Scroll down half page |
| `Ctrl-u` | Scroll up half page |
| `{` | Previous paragraph |
| `}` | Next paragraph |
| `%` | Jump to matching bracket |

## Editing (Normal Mode)

### Enter Insert Mode
| Key | Action |
|-----|--------|
| `i` | Insert before cursor |
| `a` | Insert after cursor |
| `I` | Insert at line start |
| `A` | Insert at line end |
| `o` | New line below |
| `O` | New line above |

### Delete
| Key | Action |
|-----|--------|
| `x` | Delete character |
| `dd` | Delete line |
| `dw` | Delete word |
| `d$` | Delete to end of line |
| `D` | Delete to end of line |

### Copy & Paste
| Key | Action |
|-----|--------|
| `yy` | Copy line |
| `yw` | Copy word |
| `y$` | Copy to end of line |
| `p` | Paste after |
| `P` | Paste before |

### Undo & Redo
| Key | Action |
|-----|--------|
| `u` | Undo |
| `Ctrl-r` | Redo |

## Search

| Key | Action |
|-----|--------|
| `/text` | Search forward |
| `?text` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `*` | Search word under cursor |

## Your Custom Keybindings

### File Explorer (Neo-tree)
| Key | Action |
|-----|--------|
| `<Space>e` | Toggle file explorer |
| `<Space>ef` | Reveal current file in explorer |
| `<Space>eb` | Open buffers view |
| `<Space>eg` | Open git status view |
| `<Space>er` | Reset explorer to sidebar |

**Inside file explorer:**
- `< / >` = Switch between Filesystem/Buffers/Git tabs
- `j/k` = Move up/down
- `Enter` = Open file/folder
- `<Space>` = Toggle folder open/closed
- `s` = Open in vertical split (file opens to the right)
- `S` = Open in horizontal split (file opens below)
- `t` = Open in new tab
- `w` = Pick window to open in
- `a` = New file
- `A` = New directory
- `d` = Delete
- `r` = Rename
- `y` = Copy to clipboard
- `x` = Cut to clipboard
- `p` = Paste from clipboard
- `H` = Toggle hidden files
- `R` = Refresh
- `?` = Show help
- `q` = Close

**Note:** nvim-tree is available as a backup (`nvim-tree.lua.bak`). To switch, rename the files.

### Finding Files (Telescope)
| Key | Action |
|-----|--------|
| `<Space>ff` | Find files |
| `<Space>fg` | Find text in files |
| `<Space>fb` | Find buffers (sorted recent) |
| `<Space>,` | Quick buffer switcher |
| `<Space>fr` | Recent files |
| `<Space>fh` | Help tags |
| `<Space>fd` | Find diagnostics |
| `<Space>gc` | Git commits |
| `<Space>gs` | Git status |

**Inside Telescope:**
- Type to search
- `Ctrl-j/k` = Navigate
- `Ctrl-x` = Delete buffer (in buffer picker)
- `dd` = Delete buffer (normal mode)
- `Enter` = Select
- `Esc` = Cancel

### Harpoon (Working Set - 2-4 Files)
| Key | Action |
|-----|--------|
| `<Space>a` | Add file to Harpoon |
| `Ctrl-e` | Toggle Harpoon menu |
| `<Space>1` | Jump to file 1 |
| `<Space>2` | Jump to file 2 |
| `<Space>3` | Jump to file 3 |
| `<Space>4` | Jump to file 4 |
| `Ctrl-Shift-P` | Previous in list |
| `Ctrl-Shift-N` | Next in list |

**Workflow:** Mark 2-4 files you're actively editing. Jump instantly with `<Space>1-4`.

### Windows & Buffers
| Key | Action |
|-----|--------|
| `<Space>sv` | Split vertical |
| `<Space>sh` | Split horizontal |
| `Ctrl-h` | Left window |
| `Ctrl-j` | Down window |
| `Ctrl-k` | Up window |
| `Ctrl-l` | Right window |
| `Tab` | Next buffer (bufferline) |
| `Shift-Tab` | Previous buffer (bufferline) |
| `<Space>1-9` | Go to buffer 1-9 |
| `[b` | Previous buffer |
| `]b` | Next buffer |
| `<Space>,` | Quick buffer switcher (Telescope) |
| `<Space>bd` | Delete buffer |
| `<Space>bD` | Close all buffers |
| `<Space>bo` | Close other buffers |
| `<Space>bl` | Close buffers to left |
| `<Space>br` | Close buffers to right |
| `<Space>bp` | Toggle pin buffer |
| `<Space>bP` | Delete unpinned buffers |

### Code Navigation (LSP)
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementation |
| `gr` | References |
| `K` | Show documentation |
| `gK` | Signature help |
| `<Space>rn` | Rename symbol |
| `<Space>ca` | Code action |
| `<Space>f` | Format code |

### Git Operations

**LazyGit (Main Git UI):**
| Key | Action |
|-----|--------|
| `<Space>gg` | Open LazyGit |
| `<Space>gf` | LazyGit current file |

**Telescope Git:**
| Key | Action |
|-----|--------|
| `<Space>gc` | Git commits |
| `<Space>gs` | Git status |

**Gitsigns (Inline Hunks):**
| Key | Action |
|-----|--------|
| `]c` | Next hunk |
| `[c` | Previous hunk |
| `<Space>gp` | Preview hunk |
| `<Space>gS` | Stage hunk |
| `<Space>gr` | Reset hunk |
| `<Space>gR` | Stage buffer |
| `<Space>gU` | Reset buffer |
| `<Space>gu` | Undo stage hunk |
| `<Space>gb` | Blame line |
| `<Space>gd` | Diff this |

### Comments
| Key | Action |
|-----|--------|
| `gcc` | Toggle line comment |
| `gbc` | Toggle block comment |
| `gc` (visual) | Toggle comment |

### Linting & Diagnostics
| Key | Action |
|-----|--------|
| `<Space>ll` | Trigger linting manually |
| `<Space>ls` | Toggle shellcheck strict mode |
| `<leader>de` | Show diagnostic under cursor |
| `<leader>dl` | Open diagnostic list |
| `<leader>xx` | Open Trouble diagnostics |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

**Note:**
- Inline diagnostics are **hidden by default** to reduce visual clutter
- Use `<Space>de` to view diagnostics under cursor
- Use `<Space>td` to toggle inline messages on/off
- Shellcheck strict mode enables all style checks (SC2250, SC2001, SC2292, SC2312)

### AI Assistant
| Key | Action |
|-----|--------|
| `<Space>aa` | Open Claude chat |

### Terminal
| Key | Action |
|-----|--------|
| `Ctrl-\` | Toggle terminal |
| `<Space>th` | Horizontal terminal |
| `<Space>tv` | Vertical terminal |
| `<Space>tf` | Floating terminal |
| `<Space>tn` | Node REPL |
| `<Space>tp` | Python REPL |
| `<Space>tH` | Htop |

### Toggle Options
| Key | Action |
|-----|--------|
| `<Space>tw` | Toggle line wrap |
| `<Space>ts` | Toggle spell check |
| `<Space>tr` | Toggle relative numbers |
| `<Space>td` | Toggle inline diagnostics (virtual text) |

### TypeScript Tools (TS/JS files)
| Key | Action |
|-----|--------|
| `<Space>To` | Organize imports |
| `<Space>Ts` | Sort imports |
| `<Space>Tu` | Remove unused |
| `<Space>Ti` | Add missing imports |
| `<Space>Tf` | Fix all |
| `<Space>Td` | Go to source definition |
| `<Space>Tr` | Rename file |
| `<Space>TR` | File references |

**In terminal mode:**
- `Esc` = Exit to normal mode
- `Ctrl-h/j/k/l` = Navigate windows
- Type normally to use terminal

## Visual Mode

### Enter Visual Mode
| Key | Action |
|-----|--------|
| `v` | Visual mode |
| `V` | Visual line mode |
| `Ctrl-v` | Visual block mode |

### In Visual Mode
| Key | Action |
|-----|--------|
| `d` | Delete selection |
| `y` | Copy selection |
| `>` | Indent right |
| `<` | Indent left |
| `J` | Move line down |
| `K` | Move line up |

## Command Mode Tricks

### Find & Replace
```
:%s/old/new/g       # Replace all in file
:%s/old/new/gc      # Replace with confirmation
:s/old/new/g        # Replace in current line
```

### Line Numbers
```
:set number         # Show line numbers
:set relativenumber # Show relative numbers
:42                 # Go to line 42
```

### Multiple Files
```
:e filename         # Edit file
:bn                 # Next buffer
:bp                 # Previous buffer
:bd                 # Delete buffer
```

## Common Patterns

### Edit a word
```
1. Position cursor on word
2. Press 'ciw' (change inner word)
3. Type new word
4. Press Esc
```

### Delete inside quotes
```
1. Cursor inside "quotes"
2. Press 'di"' (delete inside quotes)
```

### Delete inside brackets
```
1. Cursor inside {brackets}
2. Press 'di{' (delete inside brackets)
```

### Duplicate a line
```
1. Position on line
2. Press 'yy' (copy)
3. Press 'p' (paste)
```

### Move a line
```
1. Position on line
2. Press 'dd' (cut)
3. Move to destination
4. Press 'p' (paste)
```

## Text Objects

Combine with `d` (delete), `c` (change), `y` (copy):

| Object | Meaning |
|--------|---------|
| `iw` | Inner word |
| `aw` | A word (with space) |
| `i"` | Inside quotes |
| `a"` | Around quotes |
| `i(` | Inside parentheses |
| `a(` | Around parentheses |
| `i{` | Inside braces |
| `a{` | Around braces |
| `it` | Inside tag (HTML) |
| `at` | Around tag (HTML) |
| `ip` | Inside paragraph |
| `ap` | Around paragraph |

**Examples:**
- `diw` = Delete inner word
- `ci"` = Change inside quotes
- `ya{` = Copy around braces
- `dip` = Delete inside paragraph

## Autocompletion

**When typing (Insert mode):**
- `Ctrl-Space` = Trigger completion
- `Ctrl-j/k` = Navigate suggestions
- `Tab` = Accept / next item
- `Enter` = Confirm
- `Ctrl-e` = Close menu

## Tips

1. **Press `<Space>` and wait** - See all leader commands
2. **Press `Esc` when confused** - Returns to Normal mode
3. **Use `.` to repeat** - Last command
4. **Use `u` liberally** - Undo is your friend
5. **`:help <topic>`** - Built-in documentation

## Developer Productivity Tips

### Quick File Navigation
```
<Space>ff       Find files by name
<Space>fg       Search content in files (grep)
<Space>fr       Recent files
<Space>,        Quick buffer switcher
<Space>fb       All buffers (sorted recent)
gf              Go to file under cursor
Ctrl-^          Toggle between last two files
```

### Harpoon Workflow (Recommended)
```
<Space>a        Mark file (add to working set)
<Space>1-4      Jump to marked files 1-4
Ctrl-e          Toggle Harpoon menu
Ctrl-Shift-N/P  Next/Previous in list
```

**Best Practice:**
1. Mark 2-4 files you're actively editing with `<Space>a`
2. Jump instantly with `<Space>1`, `<Space>2`, etc.
3. For other files, use `<Space>,` (Telescope buffer switcher)
4. Update working set as you switch tasks

### Code Navigation (LSP)
```
gd              Go to definition
gD              Go to declaration
gi              Go to implementation
gr              References
K               Show documentation
gK              Signature help
[d              Previous diagnostic
]d              Next diagnostic
<Space>rn       Rename symbol
<Space>ca       Code actions
<Space>f        Format code
```

### Multi-file Editing
```
:args *.js      Add files to args list
:argdo %s/old/new/ge | update   Replace in all files
:bufdo          Execute command in all buffers
:windo          Execute command in all windows
:cfdo           Execute command in quickfix list
```

### Window Management
```
<Space>sv       Split vertical
<Space>sh       Split horizontal
Ctrl-w=         Equal width/height
Ctrl-w_         Maximize height
Ctrl-w|         Maximize width
Ctrl-w r        Rotate windows
Ctrl-w x        Exchange windows
```

### Advanced Search & Replace
```
/\<word\>       Search exact word
/\vpattern      Very magic mode (easier regex)
:%s/old/new/gc  Replace with confirmation
:%s/old/new/g   Replace all
:'<,'>s/old/new/g   Replace in visual selection
:g/pattern/d    Delete lines matching pattern
:v/pattern/d    Delete lines NOT matching
```

### Macros (Record & Replay)
```
qa              Start recording macro in register 'a'
q               Stop recording
@a              Play macro 'a'
@@              Replay last macro
5@a             Replay macro 5 times
:reg            View all registers
```

### Marks & Jumps
```
ma              Set mark 'a' at cursor
'a              Jump to mark 'a'
mA              Set global mark 'A'
'A              Jump to global mark 'A'
``              Jump to last position
'.              Jump to last change
Ctrl-o          Jump to older position
Ctrl-i          Jump to newer position
:marks          View all marks
:jumps          View jump list
```

### LSP Workflow Integration
```
<Space>ca       Code actions (imports, fixes)
<Space>rn       Rename across project
gr              Find all references
K               Inline documentation
gK              Signature help
[d / ]d         Navigate diagnostics
<Space>f        Auto-format code
```

### Git Integration (LazyGit)
```
<Space>gg       Open LazyGit
<Space>gf       LazyGit current file
In LazyGit:
  Space         Stage/unstage
  a             Stage all
  c             Commit
  P             Push
  p             Pull
  d             View diff
  ?             Help
```

### Git (Inline with Gitsigns)
```
]c              Next hunk
[c              Previous hunk
<Space>gp       Preview hunk
<Space>gS       Stage hunk
<Space>gr       Reset hunk
<Space>gR       Stage buffer
<Space>gU       Reset buffer
<Space>gu       Undo stage hunk
<Space>gb       Blame line
<Space>gd       Diff this
```

### Git (Telescope)
```
<Space>gc       Git commits
<Space>gs       Git status
```

### AI Assistant (Avante)
```
<Space>aa       Open Claude chat
Visual select → <Space>aa → Ask about code
a               Apply suggestion
A               Apply all suggestions
```

### Telescope Power User
```
<Space>ff       Find files
<Space>fg       Live grep
<Space>fc       Find word under cursor
<Space>fb       Buffers
<Space>fh       Help tags
In Telescope:
  Ctrl-j/k      Navigate
  Ctrl-u/d      Scroll preview
  Ctrl-q        Send to quickfix
  Tab           Select multiple
```

### Text Objects (Powerful!)
```
diw             Delete inner word
ciw             Change inner word
di"             Delete inside quotes
ci(             Change inside parentheses
da{             Delete around braces
yit             Yank inside HTML tag
vip             Select paragraph
```

Combinations:
- `ci{` = Change inside braces
- `da"` = Delete around quotes (including quotes)
- `yi(` = Yank inside parentheses
- `va[` = Select around brackets

### File Operations
```
:e filename     Edit file
:e .            File explorer (netrw)
:E              Explore current dir
<Space>e        Toggle neo-tree
:w filename     Save as
:sav filename   Save as and edit new file
:bd             Delete buffer
:bd!            Force delete buffer
```

### Quickfix & Location List
```
:copen          Open quickfix
:cclose         Close quickfix
:cn             Next item
:cp             Previous item
:cfdo           Execute in all quickfix files
:lopen          Open location list
```

### Most Important Commands Summary

**Survival:**
```
i       Start typing
Esc     Normal mode
:w      Save
:q      Quit
u       Undo
Ctrl-r  Redo
```

**Navigation:**
```
<Space>ff   Find files
gd          Go to definition
K           Documentation
]c          Next change (Git)
```

**Editing:**
```
ciw         Change word
di"         Delete in quotes
gcc         Comment line
<Space>f    Format code
```

**Git:**
```
<Space>gg   LazyGit
<Space>gp   Preview hunk
<Space>gc   Git commits
```

---

**Keep this reference handy while developing!**

**Learn more:** Run `vimtutor` in terminal • `:help` in Neovim • `?` in Lazygit
