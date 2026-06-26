# Ghostty Terminal Configuration

Ghostty configuration optimized for Claude Code + Neovim workflow.

Based on: https://danielmiessler.com/blog/replacing-cursor-with-neovim-claude-code

## Installation

### 1. Install Ghostty (if not already installed)

```bash
brew install --cask ghostty
```

### 2. Stow the configuration

From your dotfiles directory:

```bash
cd ~/.dotfiles
stow ghostty
```

This will create the necessary symlinks:
- `~/.config/ghostty/config` → `~/.dotfiles/ghostty/.config/ghostty/config`

### 3. Restart Ghostty

Close and reopen Ghostty to load the new configuration.

### Uninstall

To remove the symlinks:

```bash
cd ~/.dotfiles
stow -D ghostty
```

## Keybindings Reference

### Splits & Panes

| Keybinding | Action |
|------------|--------|
| `Cmd+D` | Split right (create new vertical pane) |
| `Cmd+Shift+T` | Split down (create new horizontal pane) |
| `Ctrl+H` | Navigate to left pane |
| `Ctrl+J` | Navigate to bottom pane |
| `Ctrl+K` | Navigate to top pane |
| `Ctrl+L` | Navigate to right pane |
| `Cmd+W` | Close current pane |
| `Cmd+Shift+Z` | Toggle zoom (maximize/restore pane) |
| `Cmd+Shift+E` | Equalize all pane sizes |

### Resize Splits

| Keybinding | Action |
|------------|--------|
| `Cmd+Ctrl+H` | Resize split left |
| `Cmd+Ctrl+J` | Resize split down |
| `Cmd+Ctrl+K` | Resize split up |
| `Cmd+Ctrl+L` | Resize split right |

### Tabs

| Keybinding | Action |
|------------|--------|
| `Cmd+T` | New tab |
| `Cmd+Shift+[` | Previous tab |
| `Cmd+Shift+]` | Next tab |
| `Cmd+1-5` | Jump to tab 1-5 |

## Customization

Edit the config at `~/.dotfiles/ghostty/.config/ghostty/config` and re-stow.

### Change Font

```
font-family = "Your Preferred Font"
font-size = 14
```

### Change Theme

Currently uses `Tomorrow Night Bright` (a built-in Ghostty theme). To switch, edit `.config/ghostty/config`:

```
theme = <theme-name>
```

List all available built-in themes:
```bash
ghostty +list-themes
```

## Troubleshooting

### Config not loading?

```bash
# Verify stow created symlinks
ls -la ~/.config/ghostty/

# Check for errors
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
```

### Keybindings not working?

Make sure you've restarted Ghostty completely after stowing the config.

### Font not found?

Install Hack Nerd Font:
```bash
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font
```

### Need to update config?

After editing files in `~/.dotfiles/ghostty/`:
```bash
# Restow to update symlinks
cd ~/.dotfiles
stow -R ghostty
```

## Resources

- [Ghostty Documentation](https://ghostty.org/docs)
- [Daniel Miessler's Article](https://danielmiessler.com/blog/replacing-cursor-with-neovim-claude-code)
- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
