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
- `~/.config/ghostty/themes/onedark` → `~/.dotfiles/ghostty/.config/ghostty/themes/onedark`
- `~/.config/ghostty/themes/claude-dark` → `~/.dotfiles/ghostty/.config/ghostty/themes/claude-dark`

### 3. Restart Ghostty

Close and reopen Ghostty to load the new configuration.

### Uninstall

To remove the symlinks:

```bash
cd ~/.dotfiles
stow -D ghostty
```

## Quick Start - Claude Code + Neovim Workflow

### The Perfect Layout

```
┌─────────────────┬──────────────────┐
│                 │                  │
│  Claude Code    │    Neovim        │
│  (Left pane)    │  (Right pane)    │
│                 │                  │
├─────────────────┴──────────────────┤
│         Shell (Bottom pane)        │
└────────────────────────────────────┘
```

### Setting Up Your Workspace

1. **Open Ghostty**
2. **Run Claude Code** in the first pane:
   ```bash
   claude
   ```
3. **Split right** with `Cmd+D` and run Neovim:
   ```bash
   nvim
   ```
4. **Split bottom** with `Cmd+Shift+T` for shell commands

### Navigation

Now you can seamlessly work between all three panes:

- `Ctrl+H` - Jump to Claude Code (left)
- `Ctrl+L` - Jump to Neovim (right)
- `Ctrl+J` - Jump to shell (bottom)
- `Ctrl+K` - Jump up

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

## Workflow Examples

### Example 1: Bug Fix

1. **Claude Code (Left)**: "I'm getting a TypeScript error in auth.ts:42"
2. **Neovim (Right)**: Open `auth.ts` and jump to line 42
3. **Claude Code**: Shows the issue and suggests a fix
4. **Neovim**: Apply the fix
5. **Shell (Bottom)**: `npm test` to verify
6. **Claude Code**: "The tests are passing now, create a commit"

### Example 2: New Feature

1. **Claude Code (Left)**: "Help me add user authentication"
2. **Claude Code**: Explains the architecture and creates files
3. **Neovim (Right)**: Edit and refine the generated code
4. **Shell (Bottom)**: Run migrations, tests, etc.
5. **Claude Code**: Review and suggest improvements

### Example 3: Learning

1. **Claude Code (Left)**: "Explain how React hooks work"
2. **Claude Code**: Provides explanation with examples
3. **Neovim (Right)**: Open your code to see practical usage
4. **Shell (Bottom)**: Run the app to see it in action

## Tips

### Muscle Memory

- Use `Ctrl+H/L` to quickly switch between Claude and Neovim
- These bindings match Vim navigation, so they're easy to remember
- `Cmd+Shift+Z` is great for temporarily focusing on one pane

### Efficient Workflow

1. Keep Claude Code always open in the left pane
2. Use Neovim in the right pane for editing
3. Use the bottom pane for git, tests, and builds
4. Never leave Ghostty - everything you need is in one window

### Multi-Project Work

- Use tabs (`Cmd+T`) for different projects
- Each tab can have its own 3-pane layout
- `Cmd+1-5` for quick tab switching

## Customization

Edit the config at `~/.dotfiles/ghostty/.config/ghostty/config` and re-stow.

### Change Font

```
font-family = "Your Preferred Font"
font-size = 14
```

### Change Theme

Available themes:
- `onedark` (current) - OneDarkPro Dark variant - pure black background with enhanced contrast
- `claude-dark` - Inspired by Anthropic's Claude brand colors with warm orange accents
- `tokyonight_night` - TokyoNight dark theme

To switch themes, edit `.config/ghostty/config`:
```
theme = claude-dark
```

Or create your own theme file in `.config/ghostty/themes/`.

**Note:** Ghostty also includes hundreds of built-in themes. You can list them all with:
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

## Philosophy

This setup replaces Cursor/Windsurf-style AI editors with a more flexible approach:

- **Claude Code**: AI assistance (like Cursor's AI chat)
- **Neovim**: Your powerful code editor (better than Cursor's editor)
- **Ghostty**: Fast, native terminal with vim-style navigation

You get the best of both worlds: powerful AI assistance AND your preferred editor.
