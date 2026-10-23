# Kitty Terminal Configuration

Kitty configuration with a custom Ayu theme on a true black background, no title
bar (the tab bar is the top edge of the window), a black powerline tab bar with
fixed-width tabs, and free-form splits.

## Installation

```bash
brew install --cask kitty
cd ~/.dotfiles
stow --no-folding kitty
```

`--no-folding` keeps `~/.config/kitty/` a real directory, because kitty writes
its own files there (e.g. `current-theme.conf` from `kitten themes`). The only
symlink is:

- `~/.config/kitty/kitty.conf` → `~/.dotfiles/kitty/.config/kitty/kitty.conf`

A fresh kitty install writes a commented-out default `kitty.conf`, which makes
stow refuse. Delete it first (it holds no settings) and stow again.

Reload after editing with `Cmd+Ctrl+,`, or restart kitty.

## Concepts

| Kitty term | Meaning |
| --- | --- |
| OS window | a macOS window |
| tab | a tab within an OS window |
| window | a pane inside a tab |
| layout | how a tab arranges its windows |

Two layouts are enabled: `splits`, which gives free-form horizontal and
vertical splits, and `stack`, which is used only for zoom.

## Keybindings Reference

### Splits & Panes

| Keybinding | Action |
| --- | --- |
| `Cmd+D` | Split right |
| `Cmd+Shift+D` | Split down |
| `Cmd+W` | Close current pane (asks first if a command is running) |
| `Cmd+Shift+Z` | Toggle zoom |
| `Cmd+Alt+H/J/K/L` | Focus pane left/down/up/right |
| `Cmd+Ctrl+H` / `Cmd+Ctrl+L` | Current pane narrower / wider |
| `Cmd+Ctrl+K` / `Cmd+Ctrl+J` | Current pane taller / shorter |
| `Ctrl+Shift+F7` | Focus a pane by its number |

Pane focus does **not** use `Ctrl+H/J/K/L`. Kitty can't pass those keys through
when there's no pane in that direction, so binding them would take the keys
from Neovim and tmux every time.

Overridden kitty defaults: `Cmd+Shift+D` splits down instead of closing the
pane; `Cmd+W` closes the pane, not the tab;
`Cmd+1-9` jump to tabs, not panes (panes by number stay on
`Ctrl+Shift+1-9`); `Cmd+Alt+H` is no longer "Hide Others"; `Cmd+Ctrl+L` is
no longer "clear to cursor".

### Tabs

| Keybinding | Action |
| --- | --- |
| `Cmd+T` | New tab |
| `Cmd+Shift+[` / `Cmd+Shift+]` | Previous / next tab |
| `Cmd+1-9` | Jump to tab 1-9 |
| `Cmd+Shift+I` | Rename tab |
| `Cmd+Shift+W` | Close OS window |
| `Cmd+M` | Minimise OS window |
| `Ctrl+Cmd+F` | Toggle full screen |

## Troubleshooting

### Config not loading?

```bash
ls -la ~/.config/kitty/   # kitty.conf should be a symlink into ~/.dotfiles
```

List lines kitty rejected:

```bash
kitty +runpy '
from kitty.config import load_config
b = []
load_config("'"$HOME"'/.config/kitty/kitty.conf", accumulate_bad_lines=b)
print(b or "ok")'
```

### Full option reference

```bash
kitty +runpy 'from kitty.config import *; print(commented_out_default_config())'
```

## Resources

- [Kitty Documentation](https://sw.kovidgoyal.net/kitty/)
- [Layouts](https://sw.kovidgoyal.net/kitty/overview/#layouts)
- [Mapping shortcuts](https://sw.kovidgoyal.net/kitty/mapping/)
