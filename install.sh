#!/bin/bash
#
# Public Dotfiles Installation Script
# Deploys cross-platform development environment configurations via GNU Stow
#

set -e

DOTFILES="$HOME/.dotfiles"

echo "Installing public dotfiles..."
echo ""

# Check prerequisites
if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow not installed"
    echo "  Install with: brew install stow"
    exit 1
fi

# Change to dotfiles directory
cd "$DOTFILES"

# Deploy the per-user stow ignore list before any stow runs. A global-ignore
# file REPLACES stow's built-in defaults, so .stow-global-ignore reproduces them
# and adds macOS junk (.DS_Store, ._*, .Spotlight-V100, …) — stow doesn't read
# .gitignore, so without this Finder droppings get stowed and cause conflicts.
ln -sfn "$DOTFILES/.stow-global-ignore" "$HOME/.stow-global-ignore"

echo "Deploying configurations..."
echo ""

# --- Files-only packages (no folding concerns) ---

echo "  • Zsh → ~/.zshrc, ~/.zshenv"
stow -v zsh

echo "  • Git → ~/.gitconfig.public, ~/.global.gitignore"
stow -v git

echo "  • Homebrew → ~/.Brewfile"
stow -v brew

# --- ~/.config packages (mkdir prevents ~/.config itself from becoming a symlink) ---

mkdir -p "$HOME/.config"

# Folding fine — we own all files in these dirs
echo "  • Neovim → ~/.config/nvim/"
stow -v nvim

echo "  • Lazygit → ~/.config/lazygit/"
stow -v lazygit

echo "  • mpv → ~/.config/mpv/"
stow -v mpv

echo "  • Ranger → ~/.config/ranger/"
stow -v ranger

echo "  • Topgrade → ~/.config/topgrade.toml"
stow -v topgrade

# --no-folding — these tools write their own files to config dir
echo "  • Ghostty → ~/.config/ghostty/"
stow -v --no-folding ghostty

echo "  • Zed → ~/.config/zed/"
stow -v --no-folding zed

# --- macOS-only packages ---

if [[ "$(uname)" == "Darwin" ]]; then
    # SwiftBar — --no-folding: ~/.config/swiftbar/plugins is a real dir shared with the
    # private dotfiles' LattIQ Connect plugin. Point SwiftBar at it explicitly
    # since its default plugin folder is elsewhere.
    echo "  • SwiftBar plugins → ~/.config/swiftbar/plugins/"
    mkdir -p "$HOME/.config/swiftbar/plugins"
    stow -v --no-folding swiftbar
    defaults write com.ambar.SwiftBar PluginDirectory "$HOME/.config/swiftbar/plugins" 2>/dev/null || true

    # --no-folding — Colima writes VM state into this dir; only the yaml is ours
    echo "  • Colima → ~/.config/colima/default/colima.yaml"
    mkdir -p "$HOME/.config/colima/default"
    stow -v --no-folding colima

    # Load the autostart LaunchAgent so Colima boots at login. The plist pins
    # COLIMA_HOME, which launchd would otherwise not inherit from the shell.
    echo "  • Colima autostart → ~/Library/LaunchAgents/com.guna.colima.plist"
    launchctl bootstrap "gui/$(id -u)" \
        "$HOME/Library/LaunchAgents/com.guna.colima.plist" 2>/dev/null || true
fi

# --- Linux-only packages ---

if [[ "$(uname)" == "Linux" ]]; then
    # XFCE-specific packages
    if command -v xfce4-panel &> /dev/null; then
        echo "  • XFCE4 → ~/.config/xfce4/, ~/.local/share/applications/"
        mkdir -p "$HOME/.local/share/applications"
        stow -v --no-folding xfce4
        update-desktop-database "$HOME/.local/share/applications/"

        # Set LightDM login screen to solid black background
        if [[ -f /etc/lightdm/lightdm-gtk-greeter.conf ]]; then
            echo "  • LightDM → solid black login background"
            sudo sed -i 's|^background=.*|background=#000000|' /etc/lightdm/lightdm-gtk-greeter.conf
            sudo sed -i 's|^#\?user-background=.*|user-background=false|' /etc/lightdm/lightdm-gtk-greeter.conf
        fi
    fi
fi

echo ""
echo "Public dotfiles installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Install Homebrew packages: brew bundle --global"
echo "  2. Restart shell: exec zsh"
echo ""
echo "Tip: machine-local shell functions go in ~/.config/zsh/local.d/*.sh"
echo "     (sourced automatically; never committed to this repo)."
echo ""
