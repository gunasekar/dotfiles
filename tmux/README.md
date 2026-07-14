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

Prefix is the default `Ctrl+b` — press it, release, then the key.

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

**Scrollback** is 50k lines — agent runs are verbose enough to bury their own
starting point at tmux's 2k default.

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

### Images need allow-passthrough

`set -g allow-passthrough on` is required by `image.nvim` / `diagram.nvim` —
without it, tmux swallows the Kitty graphics escapes and diagrams render
nothing. See `nvim/.config/nvim/lua/plugins/diagram.lua`.

### Prefix stays Ctrl+b

`Ctrl+a` (the classic Screen rebind) shadows readline **beginning-of-line** in
zsh. `Ctrl+Space` shadows **blink.cmp's force-completion key**
(`nvim/.config/nvim/lua/plugins/lsp/completion.lua`). `Ctrl+b`'s only casualty
is readline backward-char, which the arrow keys already cover.

### Mouse mode is off

`set -g mouse on` hands scroll and click-drag to tmux copy-mode, which breaks
Ghostty's native scrollback and select-to-copy inside panes. Commented out in
`tmux.conf` with the trade-off spelled out. Scroll with `Ctrl+b` `[`, then `q`.

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
