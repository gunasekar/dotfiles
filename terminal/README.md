# Terminal.app (macOS)

**Default terminal** for this machine. kitty stays installed as an alternate
(`open -a kitty`) when you want GPU splits or kitty-only features.

`install.sh` also asks Launch Services to open `.sh` / `.bash` / `.zsh` in
Terminal (kitty’s cask often steals that). macOS may pop a Finder confirmation —
accept it, or use Get Info → Open with → Terminal → Change All.

Minimal profile: true black background, Hack Nerd Font Mono, Option-as-Meta,
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

- `~/.config/terminal/Black.terminal` → `~/.dotfiles/terminal/.config/terminal/Black.terminal`

Terminal.app does not live-read that file. `install.sh` merges it into
`~/Library/Preferences/com.apple.Terminal.plist` and sets **Black** as the
Default and Startup profile. It does **not** open a Terminal window (that used
to trigger a “terminate running processes” dialog on close). Re-run
`./terminal/install.sh` after edits or `git pull`; open a **new** window
(`Cmd+N`) — or quit Terminal once — to pick up changes.

## Profile settings

| Setting | Value |
| --- | --- |
| Name | Black |
| Font | Hack Nerd Font Mono 12 |
| Background | `#000000` |
| Foreground / ANSI | Ayu-on-black (same palette as kitty) |
| Option as Meta | yes |
| When the shell exits | Close the window |
| Title bar | `user@host:cwd` |
| Tab title | Same: `user@host:cwd` |
| Tab bar | Hidden when there is only one tab |

Window size default: 120×30. The tab bar appears when you open a second tab
(`Cmd+T`); hide/show manually with `⇧⌘T`. Opening/closing tabs can change
window height when the bar appears or disappears — that is Terminal.app.

**Titles.** Black leaves Terminal’s window *and* tab title checkboxes off
(including `Show*InTabTitle` — those produced `~ — … — -zsh`). `~/.zshrc`
sets `user@host:cwd` on OSC window (`]2`) only and clears the tab title
(`]1`): setting both to the same string made the title bar
`user@host:~ — user@host:~`. With `]1` empty, Terminal reuses the window
title in the tab bar (Terminal.app only).

## Regenerating the profile

Fonts and colours in `.terminal` files are archived Cocoa objects, so the
committed `Black.terminal` is produced by a small Swift generator (needs the
font installed on the machine that runs it):

```bash
cd ~/.dotfiles/terminal
swift generate-black-terminal.swift .config/terminal/Black.terminal
./install.sh
```

## Removal

```bash
cd ~/.dotfiles && stow -D terminal
# Then in Terminal → Settings → Profiles, delete "Black" if you no longer want it.
```

## Resources

- [Import and export Terminal profiles](https://support.apple.com/guide/terminal/import-and-export-terminal-profiles-trml4299c696/mac)
- [Profiles Shell settings](https://support.apple.com/guide/terminal/change-profiles-shell-settings-trmlshll/mac)
