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
shell, without clicking through them.

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
