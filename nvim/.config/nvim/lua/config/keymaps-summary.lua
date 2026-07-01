-- ══════════════════════════════════════════════════════════════════════════════
-- NEOVIM KEYMAPS REFERENCE
-- ══════════════════════════════════════════════════════════════════════════════
-- This file is for reference only - actual keymaps are defined in plugin files
-- and config/keymaps.lua
--
-- Leader key: Space
-- Last updated: 2025-12-21
-- ══════════════════════════════════════════════════════════════════════════════

--[[

╔══════════════════════════════════════════════════════════════════════════════╗
║                         🚀 ESSENTIAL BASICS                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝

MODE SWITCHING
-------------
i               Enter insert mode (start typing)
a               Insert after cursor
A               Insert at end of line
o               New line below
O               New line above
v               Visual mode (select text)
V               Visual line mode
Ctrl-v          Visual block mode
Esc or jk       Return to normal mode (jk in insert mode)
:               Command mode

SAVE & QUIT
-----------
<Space>w        Save file
<Space>W        Save all files
<Space>q        Quit
<Space>Q        Quit all without saving
:w              Save
:q              Quit
:wq or :x       Save and quit
:q!             Force quit without saving
ZZ              Save and quit
ZQ              Quit without saving

UNDO & REDO
-----------
u               Undo
Ctrl-r          Redo


╔══════════════════════════════════════════════════════════════════════════════╗
║                         📍 NAVIGATION                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

BASIC MOVEMENT
--------------
h j k l         Left, Down, Up, Right
w / b           Next/previous word
0 / $           Start/end of line
gg / G          Top/bottom of file
{ / }           Previous/next paragraph
%               Jump to matching bracket
Ctrl-d          Scroll down half page (centers)
Ctrl-u          Scroll up half page (centers)
n / N           Next/previous search (centers)

WINDOW NAVIGATION
-----------------
Ctrl-h          Move to left window
Ctrl-j          Move to bottom window
Ctrl-k          Move to top window
Ctrl-l          Move to right window

WINDOW MANAGEMENT
-----------------
<Space>sv       Split window vertically
<Space>sh       Split window horizontally
<Space>sx       Close current split
<Space>se       Make splits equal size
Ctrl-Up         Increase window height
Ctrl-Down       Decrease window height
Ctrl-Left       Decrease window width
Ctrl-Right      Increase window width


╔══════════════════════════════════════════════════════════════════════════════╗
║                         ✏️  EDITING                                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

INSERT MODE SELECTION (IDE-LIKE)
--------------------------------
Shift-Left      Select left
Shift-Right     Select right
Shift-Up        Select up
Shift-Down      Select down
Shift-Home      Select to line start
Shift-End       Select to line end

DELETE
------
x               Delete character
dd              Delete line
dw              Delete word
d$ or D         Delete to end of line
<Space>d        Delete without yanking (normal/visual)

COPY & PASTE
------------
yy              Copy (yank) line
yw              Copy word
y$              Copy to end of line
p               Paste after cursor
P               Paste before cursor
<Space>y        Yank to system clipboard
<Space>Y        Yank line to system clipboard
Yp              Yank absolute file path
Yr              Yank relative file path
Yf              Yank filename only
<Space>p        Paste without yanking (visual mode)
v p             Paste without yanking (replaces selection)

CHANGE
------
ciw             Change inner word
ci"             Change inside quotes
ci(             Change inside parentheses
ci{             Change inside braces
cit             Change inside HTML tag

INDENTING
---------
> (visual)      Indent right (stays in visual mode)
< (visual)      Indent left (stays in visual mode)
>>              Indent current line right
<<              Indent current line left

MOVE LINES
----------
Alt-j           Move line down
Alt-k           Move line up
J (visual)      Move selected text down
K (visual)      Move selected text up

OTHER
-----
J               Join lines (keeps cursor position)
Ctrl-a          Select all
.               Repeat last command


╔══════════════════════════════════════════════════════════════════════════════╗
║                         📁 FILE & BUFFER MANAGEMENT                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

FILE EXPLORER (NEO-TREE)
------------------------
<Space>e        Toggle Neo-tree file explorer
<Space>ef       Reveal current file in explorer

In Neo-tree:
  Enter         Open file/folder
  a             New file
  A             New directory
  d             Delete
  r             Rename
  y             Copy file (for paste operation)
  Yp            Yank absolute file path
  Yr            Yank relative file path
  Yf            Yank filename only
  x             Cut to clipboard
  p             Paste from clipboard
  s             Open in vertical split
  S             Open in horizontal split
  H             Toggle hidden files
  R             Refresh
  ?             Show help
  q             Close

FINDING FILES (TELESCOPE)
------------------------
<Space>ff       Find files by name
<Space>fr       Find recent files
<Space>fg       Find text in files (live grep)
<Space>fc       Find word under cursor
<Space>fb       Find buffers (sorted by recent)
<Space>,        Quick buffer switcher
<Space>fh       Find help topics
<Space>fd       Find diagnostics

Telescope keymaps (inside Telescope):
  Ctrl-j/k      Navigate up/down
  Ctrl-u/d      Scroll preview (disabled - use default Ctrl-u/d)
  Ctrl-x        Delete buffer (in buffer picker)
  Ctrl-q        Send to quickfix list
  dd            Delete buffer (normal mode in buffer picker)
  q             Close (normal mode)
  Enter         Select item
  Esc           Cancel

GIT (TELESCOPE)
---------------
<Space>gc       Git commits
<Space>gs       Git status

SNACKS PICKER (ALTERNATIVE)
---------------------------
<Space><space>  Smart find (Snacks)
<Space>:        Command history
<Space>sn       Search notifications
<Space>bb       Browse buffers (Snacks)

BUFFER NAVIGATION
-----------------
Tab             Next buffer
Shift-Tab       Previous buffer
Shift-h         Previous buffer (alternative)
Shift-l         Next buffer (alternative)
[b              Previous buffer (alternative)
]b              Next buffer (alternative)
<Space>1-9      Go to buffer 1-9
<Space>,        Quick buffer switcher (Telescope)
Ctrl-^          Toggle between last two files

BUFFER MANAGEMENT
-----------------
<Space>bd       Delete buffer (keeps window)
<Space>bD       Delete all buffers
<Space>bo       Close other buffers
:bd             Delete buffer (safer version, mapped to :Bd)


╔══════════════════════════════════════════════════════════════════════════════╗
║                         🔍 SEARCH & REPLACE                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝

SEARCH
------
/text           Search forward
?text           Search backward
n               Next match (centers screen)
N               Previous match (centers screen)
*               Search word under cursor forward
#               Search word under cursor backward
Esc             Clear search highlight

REPLACE (COMMAND MODE)
----------------------
:%s/old/new/g       Replace all in file
:%s/old/new/gc      Replace with confirmation
:s/old/new/g        Replace in current line
:'<,'>s/old/new/g   Replace in visual selection


╔══════════════════════════════════════════════════════════════════════════════╗
║                         💻 CODE NAVIGATION & LSP                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

LSP NAVIGATION
--------------
gd              Go to definition
gD              Go to declaration
gi              Go to implementation
gr              Go to references
K               Show hover documentation
gK              Signature help

LSP ACTIONS
-----------
<Space>rn       Rename symbol
<Space>ca       Code action

DIAGNOSTICS
-----------
[d              Previous diagnostic
]d              Next diagnostic
<Space>de       Show diagnostic error (float)
<Space>dl       Open diagnostic list
<Space>td       Toggle diagnostic virtual text


╔══════════════════════════════════════════════════════════════════════════════╗
║                         🎨 CODE FORMATTING & QUALITY                         ║
╚══════════════════════════════════════════════════════════════════════════════╝

FORMATTING (CONFORM)
--------------------
<Space>f        Format buffer (primary)
<Space>cf       Format buffer (alternative)

Both work in normal and visual mode. Auto-formats on save.

LINTING
-------
<Space>ll       Trigger linting manually
<Space>ls       Toggle shellcheck strict mode

COMMENTS (COMMENT.NVIM)
-----------------------
gcc             Toggle line comment
gbc             Toggle block comment
gc (motion)     Comment motion (e.g., gcap = comment paragraph)
gc (visual)     Comment selection
gb (motion)     Block comment motion
gb (visual)     Block comment selection
gcO             Comment line above
gco             Comment line below
gcA             Comment at end of line


╔══════════════════════════════════════════════════════════════════════════════╗
║                         🌳 GIT OPERATIONS                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

LAZYGIT (MAIN GIT UI)
---------------------
<Space>gg       Open LazyGit (full interface)
<Space>gf       LazyGit current file

In LazyGit:
  j/k or ↑/↓    Navigate
  Space         Stage/unstage file
  a             Stage all
  c             Commit
  P             Push
  p             Pull
  d             View diff
  ?             Help
  q             Quit

GIT HUNKS (GITSIGNS)
--------------------
]c              Next hunk (change)
[c              Previous hunk (change)
<Space>hp       Preview hunk (floating window)
<Space>hb       Blame line (full)
<Space>hd       Diff this
<Space>hD       Diff this ~

STAGE/UNSTAGE (GITSIGNS)
------------------------
<Space>hs       Stage hunk
<Space>hS       Stage buffer (entire file)
<Space>hu       Undo stage hunk
<Space>hr       Reset hunk ⚠️  (discards changes)
<Space>hR       Reset buffer ⚠️  (discards all changes)

GIT (SNACKS)
------------
<Space>gB       Git browse (open in browser)
<Space>gl       Git log (Snacks)

GIT (TELESCOPE)
---------------
<Space>gc       Git commits
<Space>gs       Git status

VISUAL INDICATORS
-----------------
Look for these on the left side of your files:
  │ (green)     Added lines
  │ (yellow)    Modified lines
  _ (red)       Deleted lines
  ┆ (gray)      Untracked lines


╔══════════════════════════════════════════════════════════════════════════════╗
║                         💻 TERMINAL                                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

TERMINAL TOGGLE
---------------
Ctrl-`          Toggle bottom panel (current terminal session) - all modes
Esc             Exit terminal mode (to normal mode)
Ctrl-h/j/k/l    Navigate windows from terminal

BOTTOM PANEL SESSIONS (supports multiple terminals, like the agent panel)
--------------------------------------------------------------------------
Ctrl-Shift-`    New terminal session - all modes
Ctrl-Shift-L    Next terminal session - all modes
Ctrl-Shift-H    Prev terminal session - all modes
<Space>tt       New terminal session
<Space>t]       Next terminal session
<Space>t[       Prev terminal session
<Space>H        Toggle htop/btop monitor (float)

PANEL / SESSION PICKER
----------------------
<Space>up       Pick any panel or session (explorer, every terminal
                and agent session by name) - jumps straight to it
<Space>uP       Focus the main editor window


╔══════════════════════════════════════════════════════════════════════════════╗
║                            🐛 DIAGNOSTICS                                     ║
╚══════════════════════════════════════════════════════════════════════════════╝

DIAGNOSTICS (CORE)
------------------
[d              Previous diagnostic
]d              Next diagnostic
<Space>de       Show diagnostic error (floating window)
<Space>dl       Open diagnostic list (location list)
<Space>td       Toggle inline diagnostic text (virtual text)


╔══════════════════════════════════════════════════════════════════════════════╗
║                         🎛️  TOGGLES & OPTIONS                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

BASIC TOGGLES
-------------
<Space>tw       Toggle line wrap
<Space>ts       Toggle spell check
<Space>tr       Toggle relative line numbers
<Space>td       Toggle diagnostic virtual text


╔══════════════════════════════════════════════════════════════════════════════╗
║                         🤖 AI AGENT                                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

CLAUDE CODE / CURSOR AGENT (right panel)
-----------------------------------------
Ctrl-\          Toggle right panel (current session)
Ctrl-Shift-\    Open new agent session
<Space>ac       Toggle right panel
<Space>as       Send selection/buffer to active agent
<Space>a]       Next agent session
<Space>a[       Previous agent session
Ctrl-Shift-]    Next agent session (all modes)
Ctrl-Shift-[    Previous agent session (all modes)
Esc             Leave terminal mode (back to Neovim normal)
Ctrl-Esc        Interrupt agent (send ^C to process)


╔══════════════════════════════════════════════════════════════════════════════╗
║                         🔔 NOTIFICATIONS & UI                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

NOTIFICATIONS (SNACKS)
----------------------
<Space>un       Dismiss all notifications
<Space>nh       Notification history
<Space>sn       Search notifications

DASHBOARD
---------
<Space>;        Open dashboard

WHICH-KEY
---------
<Space>?        Show buffer local keymaps
<Space>         Press Space and wait to see all leader commands


╔══════════════════════════════════════════════════════════════════════════════╗
║                         🎯 TEXT OBJECTS (POWERFUL!)                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

Combine with operators: d (delete), c (change), y (yank), v (select)

WORD OBJECTS
------------
iw              Inner word
aw              A word (includes surrounding space)

QUOTE/BRACKET OBJECTS
---------------------
i"              Inside double quotes
a"              Around double quotes (includes quotes)
i'              Inside single quotes
a'              Around single quotes
i`              Inside backticks
a`              Around backticks
i(  i)  ib      Inside parentheses
a(  a)  ab      Around parentheses
i[  i]          Inside square brackets
a[  a]          Around square brackets
i{  i}  iB      Inside curly braces
a{  a}  aB      Around curly braces
i<  i>          Inside angle brackets
a<  a>          Around angle brackets

TAG OBJECTS (HTML/XML)
----------------------
it              Inside tag
at              Around tag (includes tags)

PARAGRAPH/BLOCK
---------------
ip              Inside paragraph
ap              Around paragraph
is              Inside sentence
as              Around sentence

GIT OBJECTS (GITSIGNS)
----------------------
ih              Inside hunk (use with visual/operator)

EXAMPLES
--------
diw             Delete inner word
ciw             Change inner word
di"             Delete inside quotes
ci(             Change inside parentheses
da{             Delete around braces (includes braces)
yit             Yank inside HTML tag
vip             Select paragraph
vih             Select hunk (git)
dih             Delete hunk (git)


╔══════════════════════════════════════════════════════════════════════════════╗
║                         ⚡ ADVANCED FEATURES                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

MACROS
------
qa              Start recording macro in register 'a'
q               Stop recording
@a              Play macro 'a'
@@              Replay last macro
5@a             Replay macro 5 times

MARKS & JUMPS
-------------
ma              Set mark 'a' at cursor position
'a              Jump to mark 'a'
mA              Set global mark 'A' (works across files)
'A              Jump to global mark 'A'
``              Jump to position before last jump
'.              Jump to last change
Ctrl-o          Jump to older position in jump list
Ctrl-i          Jump to newer position in jump list

REGISTERS
---------
"ayy            Yank line to register 'a'
"ap             Paste from register 'a'
"+y             Yank to system clipboard
"+p             Paste from system clipboard
:reg            View all registers

COMMAND MODE TRICKS
-------------------
:42             Go to line 42
:10,20d         Delete lines 10-20
:g/pattern/d    Delete all lines matching pattern
:v/pattern/d    Delete all lines NOT matching pattern
:%!command      Filter buffer through shell command
:earlier 5m     Go back 5 minutes in undo history
:later 10s      Go forward 10 seconds in undo history


╔══════════════════════════════════════════════════════════════════════════════╗
║                         💡 RECOMMENDED WORKFLOWS                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

DAILY DEVELOPMENT WORKFLOW
--------------------------
1. <Space>ff        Find and open file
2. <Space>e         Toggle file explorer for context
3. Edit your code
4. <Space>f         Format code
5. <Space>ca        Apply code actions if needed
6. <Space>gg        Review changes in LazyGit
7. Stage, commit, push from LazyGit

QUICK FILE NAVIGATION
---------------------
<Space>ff       Find files by name (use this first)
<Space>fg       Search content in files (grep)
<Space>fr       Jump to recent files
<Space>,        Quick buffer switcher (2-10 open files)
Tab             Cycle through buffers
<Space>1-9      Jump to specific buffer by number
gf              Go to file path under cursor

CODE REVIEW WORKFLOW
--------------------
1. ]c               Jump to next change
2. <Space>hp        Preview the hunk
3. <Space>hs        Stage good changes
4. <Space>hr        Reset bad changes
5. <Space>gg        Open LazyGit to commit

REFACTORING WORKFLOW
--------------------
1. gd               Go to definition
2. gr               See all references
3. <Space>rn        Rename symbol everywhere
4. <Space>ca        Apply code actions
5. <Space>f         Format after changes

DEBUGGING ERRORS
----------------
1. ]d               Jump to next diagnostic
2. <Space>de        Read error message
3. K                Check documentation
4. <Space>ca        See available fixes
5. <Space>f         Format after fixing


╔══════════════════════════════════════════════════════════════════════════════╗
║                         📊 QUICK REFERENCE                                   ║
╚══════════════════════════════════════════════════════════════════════════════╝

TOP 10 MOST IMPORTANT SHORTCUTS
--------------------------------
1.  <Space>ff       Find files (use this constantly!)
2.  <Space>fg       Search in files (grep)
3.  <Space>e        File explorer
4.  <Space>gg       Git interface (LazyGit)
5.  gcc             Comment line
6.  <Space>ca       Code actions
7.  gd              Go to definition
8.  <Space>f        Format code
9.  Ctrl-`          Terminal
10. <Space>hp       Preview git changes

MUSCLE MEMORY ESSENTIALS
------------------------
Esc or jk       Always get back to normal mode
:w Enter        Save (or <Space>w)
u               Undo anything
.               Repeat last action
*               Find word under cursor
ciw             Change word under cursor
<Space>         Wait to see all available commands


╔══════════════════════════════════════════════════════════════════════════════╗
║                         ⚠️  IMPORTANT NOTES                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝

- Leader key is Space
- In terminal mode, press Esc to return to normal mode
- Inline diagnostics hidden by default (use <Space>de to view)
- Git signs appear on left gutter (green=added, yellow=modified, red=deleted)
- Press <Space> and wait to see all available leader commands (which-key)
- Use :help <topic> for detailed help on any feature
- File paths in errors are clickable with gf (go to file)
- Bufferline shows buffers 1-9, use <Space>1-9 to jump quickly
- Auto-format on save is enabled (Conform)
- Auto-lint on save is enabled (nvim-lint)


╔══════════════════════════════════════════════════════════════════════════════╗
║                         📚 LEARNING RESOURCES                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

- Run `vimtutor` in terminal for interactive tutorial
- Use `:help <command>` in Neovim for help
- Press `?` in LazyGit for git commands
- Press `?` in Neo-tree for file explorer commands
- Press <Space> and wait to discover leader commands
- Use `:WhichKey` to see all available keymaps


════════════════════════════════════════════════════════════════════════════════
Generated: 2025-12-21
Config location: ~/.dotfiles/nvim/.config/nvim
Verified against: All plugin configurations and core keymaps
════════════════════════════════════════════════════════════════════════════════

]]

return {}
