# tmux Configuration

Session persistence for remote and agent work. The tmux server runs on the
remote host, so a dropped ssh link, a closed laptop, or quitting Ghostty leaves
your work running — Ghostty is only the viewer.

Tuned for long-running coding-agent sessions (Claude Code) and for Neovim, not
copied from a starter gist. Every non-obvious line in `tmux.conf` says why it's
there.

## Installation

tmux is already declared in `brew/.Brewfile`. `install.sh` stows it, or by hand:

```bash
cd ~/.dotfiles
stow tmux
```

This creates `~/.config/tmux/tmux.conf` → `~/.dotfiles/tmux/.config/tmux/tmux.conf`.

On a remote host, deploy the dotfiles there the same way — don't hand-edit a
`~/.tmux.conf` on the box. To remove: `stow -D tmux`.

A running server does **not** re-read the config. After editing: `prefix + r`,
or `tmux kill-server` for a clean slate.

## Daily Commands

Prefix is `Ctrl+b` **or** `Alt+Space` — press either, release, then the key.
Both are always live; the tables below show `Ctrl+b`.

| Action | Command |
|--------|---------|
| Start or re-attach a session | `tmux new -A -s my_project` |
| Detach (leaves it running) | `Ctrl+b` `d` |
| List sessions | `tmux ls` |
| Attach to a named session | `tmux a -t my_project` |
| Kill a session | `tmux kill-session -t my_project` |

`new -A -s` is the idiom worth learning: attach if it exists, create if it
doesn't. It's the whole `new`-or-`attach` dance in one command.

## Keybindings

| Keybinding | Action |
|------------|--------|
| `Ctrl+b` `\|` | Split pane right (inherits current directory) |
| `Ctrl+b` `-` | Split pane down (inherits current directory) |
| `Ctrl+b` `g` | Lazygit in a popup over the current pane |
| `Ctrl+b` `m` | Toggle the 60s silence alert for this window |
| `Ctrl+b` `r` | Reload `tmux.conf` |
| `Ctrl+b` `s` | Session switcher (`choose-tree`, built in) |
| `Ctrl+b` `z` | Zoom the current pane |
| `Ctrl+b` `[` | Enter copy-mode; `v` select, `y` copy, `q` quit |

Windows and panes number from 1 and renumber themselves when one closes.

## Agent Sessions

**Notifications.** Claude Code rings the terminal bell when it finishes or wants
input. `monitor-bell` + `bell-action any` + `visual-bell off` keep that a real
bell, so it reaches Ghostty instead of being swallowed into a tmux status line.

**Finding the idle agent.** `Ctrl+b` `m` arms a silence alert on the current
window: if the pane produces no output for 60s, the window is flagged in the
status bar. Useful for spotting an agent that finished (or stalled) while you
were elsewhere. Off by default — it's noisy on windows holding an idle shell.

**Seeing what's running.** `pane-border-status` labels every pane with its
running command, so a grid of panes tells you which is `claude` and which is a
shell, without clicking through them. Agent sessions never show it: they hold
exactly one pane, and tmux draws no border row for a lone pane.

**Agent sessions survive their frontend.** `aigent` (see `bin/.local/bin/aigent`)
runs the chosen agent inside a tmux session named `aigent-<project>`, so the agent
process outlives the terminal that started it.

This is what makes Zed's remote mode usable. Zed runs `aigent` on the ssh host as
its `terminal_init_command`, and when Zed disconnects or quits, the terminal —
and the agent process with it — dies. `claude --resume` was the only way back,
which replays the transcript into a *new* process. Held in tmux, the process
just keeps running: reconnecting re-attaches to the live conversation, so there
is nothing to resume. The same session is reachable from Ghostty with
`tmux a -t aigent-<project>`.

The picker lists what's already running for this project alongside the agents you
can start, so a new Zed thread can rejoin a session or open a fresh one — your
choice, rather than the script guessing:

```
[claude/plan]     Rework the retry budget
[cursor · #2]     Fix the flaky auth test
[claude · #3]     Migrate the schema
new     claude
new     claude/plan
…
```

- `aigent` — pick a running session to rejoin, or an agent to start
- `aigent new` — skip the running sessions and start a fresh one
- `aigent commit` — one-shot, never touches tmux
- `ctrl-x` in the picker — kill the highlighted session

`ctrl-x` is there because sessions outlive the terminal that started them, which
is the entire point — so nothing else ever reaps the ones you're done with, and
they hold their scrollback until something does.

**What is running: `@agent`, recorded rather than detected.** `aigent` stamps the
entry you picked onto the session as an `@agent` user option. Working it out from
the process afterwards is not possible — `claude` reports `claude.exe` (it's a Bun
single-file executable), `cursor-agent` reports bare `node` (a Node wrapper). Only
what launched it knows.

**What it's working on: the agent's own session name, free.** Agents publish it as
the terminal title (OSC 2), and tmux hands it back as `#{pane_title}` — Claude Code
puts its summary there, the same name `/resume` lists. Nothing has to be parsed,
hooked or scraped; it's already in tmux. Two `claude` sessions in one project would
otherwise be tellable apart only by opening them.

Two guards on that format, both load-bearing:

- tmux **seeds `pane_title` with the hostname**, so "has a title" is not "is
  non-empty" — a program that never set one reads back `airbochs`. That case falls
  back to the project directory (tab) or shows nothing (picker).
- Claude Code leads with an **animated spinner glyph** (`⠐ Set up tmux…`, a new
  frame every tick), so the first word is stripped. A glyph-less title (opencode's
  constant `OpenCode`) has no space to match and passes through whole.

Together they drive Ghostty's tab title — `claude · Set up tmux with Ghostty
terminal` — instead of the default `#S:#W · #{pane_current_command}`, which for an
agent is wrong three times over: `aigent-_dotfiles` is internal bookkeeping, the
window name is whatever tmux last auto-renamed it to, and the command is the binary.
The title reads `@agent` directly, so the window name never enters into it; every
other session keeps the default form.

The tmux **session** name is deliberately *not* renamed to the task. It's the
identity the picker matches on (`aigent-<project>`, `-2`, `-3`…), the thing
`tmux a -t aigent-myapi` addresses, and tmux forbids `.` and `:` in it — a name that
changes every time the agent re-summarises is a name nothing can rely on.

**One agent, one pane.** A session here *is* an agent: Zed and nvim each treat it as
a single view, the picker gives it a single row, and `@agent` labels it as one thing.
A second pane or window would make all three lie.

The split and new-window keys are guarded, so nothing is ever created:

```tmux
bind | if -F '#{@agent_locked}' 'display "agent session: one agent, one pane"' \
                                'split-window -h -c "#{pane_current_path}"'
```

`aigent` sets `@agent_locked` on the sessions it creates; the binding reads it from
whichever session the key was pressed in. The binding is server-global — every tmux
binding is — but the *behaviour* is per-session, so a tmux session you started
yourself splits exactly as before. `|`, `-`, `"`, `%` and `c` are all guarded.

A hook can't do this. **Every tmux hook is `after-*`** — there is no
`before-split-window` — so a hook could only create the pane and then kill it.
Refusing the key is strictly better: no pane is born, nothing is destroyed.

Deliberate routes stay open, by choice: `tmux split-window -t aigent-api` from
another terminal, `join-pane` (which fires no hook at all and is uncatchable), and
the split entries inside the `prefix + <` / `>` context menus. Each one names the
session as a target or takes real navigation to reach — none is the accidental
keypress this guards against. It's accident-prevention, not a boundary.

**No chrome either.** `aigent` sets `status off` on the sessions it creates: the
status bar would spend the bottom row on a session name you already know, a clock,
and a window list of exactly one window. The agent gets the full 24 rows of a
24-row terminal instead of 23.

It's session-scoped (`set-option -t <session>`), so a tmux session you start yourself
keeps its status bar. Verify with `tmux show-options -t <session> status`; a bare
`tmux show-options` reports whatever session you're *currently* in, which is a good
way to scare yourself into thinking it went global.

Sessions are matched by exact name or an `-N` suffix, never by prefix, so
`aigent-api` never swallows `aigent-api-worker` — a different project.

One tmux session per agent, rather than one session per project with agents as
windows. That's forced, not preferred: tmux's *current window* is session state,
not client state, so two clients attached to one session mirror each other. Zed
threads are independent clients, so under a shared session, switching to your agent
in one thread would yank another thread's view onto the same window.

**Every frontend behaves the same.** A Zed thread, an nvim agent panel and a
plain shell all run the same `aigent` script and all get the same tmux session —
nothing special-cases the caller, so an agent started from an nvim panel outlives
nvim just as a Zed one outlives Zed.

The one exception isn't a frontend: already inside tmux (`$TMUX`), `aigent` runs
the agent directly, since the process is persistent regardless and nesting would
double every prefix key.

**`n` is not a tmux thing.** `n` (see `sources/dev.sh`) just opens Neovim on a
project, in the current pane. Wrapping the editor in its own tmux session would only
buy persistence for the editor — cheap to reopen — while putting a tmux prefix key
underneath every nvim binding. Persistence is `aigent`'s job, and `aigent` does it
wherever it's run, so the editor doesn't need a session to keep its agents alive.

`tmux ls` is therefore all agents, one per session:

```
aigent-api     an agent for ~/src/api
aigent-api-2   a second one, running alongside it
```

**Scripting agents.** The reason tmux beats a plain ssh session for this work:
panes are addressable from outside.

```bash
tmux capture-pane -p -t agents:1        # read an agent's output
tmux send-keys -t agents:1 'yes' Enter  # answer its prompt
tmux new-session -d -s agents 'claude'  # launch one detached
```

This is exactly how the agent-monitoring tools out there work, and you can drive
it directly without installing any of them.

**Scrollback** is 20k lines. tmux's 2k default buries the start of an agent run,
but scrollback is the one part of tmux that costs real memory: measured at
~3.9KB per line of wide truecolor output, so a pane holding tmux-sensible's
50k lines of agent output reaches ~190MB. 20k is ~78MB, and you only pay for
lines actually produced — idle panes are free.

## Notes

### No plugins, deliberately

tmux already survives ssh drops, Wi-Fi loss, and quitting Ghostty on its own.
The popular plugins mostly buy things this config covers natively:

- **tmux-yank** → superseded by `set-clipboard on` and OSC 52 (see below).
- **tmux-sensible** → its useful options are inlined in `tmux.conf`.
- **sesh / tmux-sessionx** → `choose-tree` (`prefix + s`) is built in.
- **tmux-resurrect / continuum** → the one real gap: they restore sessions after
  a **reboot of the host**. Worth adding *only* if that starts happening; the
  cost is bootstrapping a plugin manager on every machine you ssh into.

### Clipboard over ssh

`set -s set-clipboard on` lets Neovim (or an agent) on a remote box push a yank
to the local macOS clipboard via OSC 52. The default `external` is **not**
enough — it lets tmux set the clipboard but forbids applications inside from
doing so. Ghostty advertises the `Ms` capability, so tmux has somewhere to send
it.

### Truecolor needs no configuration

Ghostty sets `TERM=xterm-ghostty`, whose terminfo declares `Tc` — tmux's own
truecolor flag — so tmux derives RGB support on its own. Verified via
`#{client_termfeatures}`, which lists `RGB` with no color options set at all.
Both lines the tutorials tell you to paste are dead config here:

```tmux
set -ag terminal-overrides ",xterm-256color:Tc"   # keys off a TERM we never send
set -as terminal-features ",xterm-ghostty:RGB"    # re-states what Tc already said
```

This relies on the `xterm-ghostty` terminfo entry existing on the remote, which
the `Match exec` hook in `~/.ssh/config` handles (see `~/.local/bin/ssh-terminfo-sync`).

### Extended keys, or half your Neovim bindings die

`set -s extended-keys on` is not optional here. Legacy terminal input can only
encode a couple of dozen control keys; anything outside that set has no byte
representation at all and silently never reaches the application inside tmux.
That covers much of the Neovim agent workflow:

| Key | Binding | Works without extended-keys? |
|---|---|---|
| `<C-\>` | toggle right panel | yes — `0x1c` is a real control code |
| `` <C-`> `` | toggle bottom panel | **no** |
| `<C-S-\>` | new agent session | **no** |
| `<C-S-]>` / `<C-S-[>` | cycle agent sessions | **no** |
| `<C-S-.>` | send context to agent | **no** |
| `<C-Esc>` | agent panel | **no** |

`Ctrl+Shift+<punct>`, `Ctrl+backtick` and `Ctrl+Esc` exist only under CSI-u.
Three settings are all required, and this is the one place Ghostty's terminfo
is **not** enough (unlike `Tc` and `Smulx`):

```tmux
set -s extended-keys always
set -s extended-keys-format csi-u
set -as terminal-features "xterm-ghostty:extkeys"
```

- **`extkeys`** — tmux requests extended keys from the terminal only *if it
  believes the terminal supports them*, and it decides that from terminfo.
  `xterm-ghostty` doesn't advertise `extkeys`, so without this tmux never asks
  Ghostty, and the keys never arrive at all.
- **`always`** — with `on`, tmux forwards only to apps that ask via tmux's own
  `modifyOtherKeys` handshake. Neovim asks via the **Kitty** protocol, which
  tmux doesn't implement ([tmux#3335](https://github.com/tmux/tmux/issues/3335)),
  so `on` forwards nothing to it.
- **`csi-u`** — the default format is `xterm` (`^[[27;6;92~`); Neovim and Claude
  Code expect `^[[92;6u`.

**These take effect when a client attaches, so `prefix + r` is not enough** —
run `tmux kill-server` and start a fresh session.

#### Shifted punctuation arrives under a different name inside tmux

Even wired up correctly, `Ctrl+Shift+<punctuation>` is reported *differently*
inside tmux, and this is not fixable in config. Bare Ghostty speaks the **Kitty**
keyboard protocol to Neovim, which reports the **base** key — `Ctrl+Shift+\` is
`<C-S-\>`. tmux doesn't implement that protocol
([tmux#3335](https://github.com/tmux/tmux/issues/3335), closed unimplemented) and
negotiates xterm's older `modifyOtherKeys`, which reports the **shifted
character** — so the same keypress arrives as `<C-S-|>`.

| Key | Outside tmux | Inside tmux |
|---|---|---|
| `Ctrl+Shift+\` | `<C-S-\>` | `<C-S-\|>` |
| `Ctrl+Shift+]` | `<C-S-]>` | `<C-S-}>` |
| `Ctrl+Shift+[` | `<C-S-[>` | `<C-S-{>` |
| `Ctrl+Shift+.` | `<C-S-.>` | `<C-S->>` |
| ``Ctrl+Shift+` `` | ``<C-S-`>`` | `<C-S-~>` |
| `Ctrl+Shift+L` | `<C-S-L>` | `<C-S-L>` — letters are fine |

So `plugins/agents.lua` and `plugins/editor/snacks.lua` bind **both spellings**
to the same action. Zellij is the only multiplexer that speaks the Kitty
protocol natively, if this ever becomes worth switching for.

To check the wiring: run `cat -v` in a pane and press `Ctrl+Shift+\`. You should
see `^[[92;6u`. Nothing at all means the negotiation isn't happening.

### Images need allow-passthrough

`set -g allow-passthrough on` is required by `image.nvim` / `diagram.nvim` —
without it, tmux swallows the Kitty graphics escapes and diagrams render
nothing. See `nvim/.config/nvim/lua/plugins/diagram.lua`.

### Colours follow Ghostty's Ayu theme

tmux's defaults are green — nobody chose that, it's just the default. The style
section instead borrows Ghostty's own palette so a tmux pane and a Ghostty split
look like the same application:

| Element | Colour | Why |
|---|---|---|
| Inactive pane border | `#555555` | exactly Ghostty's `split-divider-color` |
| Active pane border, current window | `#e6b450` | Ayu's accent — Ghostty's cursor colour |
| Status bar | `bg=default`, `fg=#686868` | transparent, so it's the terminal's true black |
| Window with a bell | `#f07178` | Ayu red — an agent wanting input should shout |
| Copy-mode selection | `#409fff` | Ghostty's `selection-background` |

### Two prefixes: Ctrl+b and Alt+Space

Both are live (`prefix` and `prefix2`). `Ctrl+b` stays primary so every
cheatsheet, guide and remote host behaves as documented; `Alt+Space` is the
comfortable one to actually reach for.

The two prefixes people usually reach for are both taken here: `Ctrl+a` (the
classic Screen rebind) shadows readline **beginning-of-line** in zsh, and
`Ctrl+Space` shadows **blink.cmp's force-completion key**
(`nvim/.config/nvim/lua/plugins/lsp/completion.lua`). `Alt+Space` is free across
zsh, Neovim (only `<A-j>`/`<A-k>` are bound) and Ghostty.

### Mouse mode is on

Click a pane to focus it, wheel to scroll history, drag a border to resize,
click a window name in the status line to switch.

The usual warning against this doesn't apply. tmux runs on the **alternate
screen** (it emits `smcup` on attach), so Ghostty's scrollback receives no pane
output at all — there is no native scrollback to trade away, and with the mouse
off the wheel does nothing whatsoever. Pane history lives only inside tmux.

The one real trade is selection: a drag belongs to tmux now. That's mostly fine,
because tmux's drag-select copies to the macOS clipboard anyway via
`set-clipboard`. Mouse release uses `copy-selection-no-clear` rather than the
default `copy-pipe-and-cancel`, so a selection copies **without** jumping back
to the live cursor — you stay scrolled with the highlight still visible. A
single click then exits copy mode (clears the highlight and returns to the live
cursor). `Escape` clears the highlight without leaving if you want another
selection; `q` or scrolling to the bottom also leave. When you want Ghostty's
own selection — to span pane borders, say — hold **Shift** while dragging:
Ghostty's `mouse-shift-capture` defaults to `false`, so Shift bypasses mouse
reporting entirely.

### Ghostty splits vs. tmux panes

Ghostty binds `Ctrl+H/J/K/L` to `goto_split` as `performable:`, so those keys
only reach tmux/Neovim when no Ghostty split exists in that direction. Locally,
prefer Ghostty's splits (`Cmd+D`, `Cmd+Shift+T`); use tmux panes on remotes,
where Ghostty has none. This is also why `vim-tmux-navigator` isn't installed —
it would put three layers in contention for the same four keys.

## Resources

- [tmux manual](https://man.openbsd.org/tmux)
- [tmux FAQ](https://github.com/tmux/tmux/wiki/FAQ) — terminfo and RGB
- [tmux Clipboard wiki](https://github.com/tmux/tmux/wiki/Clipboard) — `set-clipboard` semantics
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
