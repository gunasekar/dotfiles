# Terminal.app (macOS)

**Default terminal** for this machine. kitty stays installed as an alternate
(`open -a kitty`) when you want GPU splits or kitty-only features.

Shell scripts are **not** bound to Terminal — double-click opens TextEdit for
editing (see `setup/macos-file-handlers.sh`). Run scripts from a shell explicitly.

**g9n** profile: true black background, Hack Nerd Font Mono, Option-as-Meta,
and **close the window when the shell exits**. No splits or extra chrome —
tmux and the shell cover that.

## Installation

```bash
brew bundle --global          # includes font-hack-nerd-font
cd ~/.dotfiles
./install.sh                  # stows the profile and applies it
```

Or by hand:

```bash
cd ~/.dotfiles
stow terminal
./terminal/install.sh
```

Symlink:

- `~/.config/terminal/g9n.terminal` → `~/.dotfiles/terminal/.config/terminal/g9n.terminal`

Terminal.app does not live-read that file. `install.sh` merges it into
`~/Library/Preferences/com.apple.Terminal.plist` and sets **g9n** as the
Default and Startup profile. It does **not** open a Terminal window (that used
to trigger a “terminate running processes” dialog on close). Re-run
`./terminal/install.sh` after edits or `git pull`; open a **new** window
(`Cmd+N`) — or quit Terminal once — to pick up changes.

## Profile settings

| Setting | Value |
| --- | --- |
| Name | g9n |
| Font | Hack Nerd Font Mono 12 |
| Background | `#000000` |
| Foreground / ANSI | g9n (Ayu-on-black; same palette as kitty) |
| Option as Meta | yes |
| When the shell exits | Close the window |
| Title bar | `user@host:cwd` |
| Tab title | Same: `user@host:cwd` |
| Tab bar | Hidden when there is only one tab |

Window size default: 120×30. The tab bar appears when you open a second tab
(`Cmd+T`); hide/show manually with `⇧⌘T`. Opening/closing tabs can change
window height when the bar appears or disappears — that is Terminal.app.

**Titles.** g9n leaves Terminal’s window *and* tab title checkboxes off
(including `Show*InTabTitle` — those produced `~ — … — -zsh`). `~/.zshrc`
sets `user@host:cwd` on OSC window (`]2`) only and clears the tab title
(`]1`): setting both to the same string made the title bar
`user@host:~ — user@host:~`. With `]1` empty, Terminal reuses the window
title in the tab bar (Terminal.app only).

## Copying in tmux

Terminal.app does not support OSC 52 clipboard writes. The tmux configuration
uses `pbcopy` on local macOS for mouse selections and copy-mode `y`, including
agent sessions under Trails. Reload with `tmux source-file ~/.config/tmux/tmux.conf`
after updating. For remote tmux clipboard copying over SSH, use kitty.

## Regenerating the profile

Fonts and colours in `.terminal` files are archived Cocoa objects, so the
committed `g9n.terminal` is produced by a small Swift generator (needs the
font installed on the machine that runs it):

```bash
cd ~/.dotfiles/terminal
swift generate-g9n-terminal.swift .config/terminal/g9n.terminal
./install.sh
```

## Removal

```bash
cd ~/.dotfiles && stow -D terminal
# Then in Terminal → Settings → Profiles, delete "g9n" if you no longer want it.
```

## Resources

- [Import and export Terminal profiles](https://support.apple.com/guide/terminal/import-and-export-terminal-profiles-trml4299c696/mac)
- [Profiles Shell settings](https://support.apple.com/guide/terminal/change-profiles-shell-settings-trmlshll/mac)
