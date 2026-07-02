#!/bin/bash
#
# Bootstrap script for new machines
# Installs prerequisites needed before install.sh can run
#
# Prerequisites (manual):
#   - SSH keys added to the machine
#   - Git available (xcode-select --install on macOS, apt install git on Linux)
#

set -e

echo "Bootstrapping development environment..."
echo ""

# Check for git
if ! command -v git &>/dev/null; then
  echo "Error: Git not installed"
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "  Install with: xcode-select --install"
  elif command -v dnf &>/dev/null; then
    echo "  Install with: sudo dnf install git"
  else
    echo "  Install with: sudo apt install git"
  fi
  exit 1
fi

# Install Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Set up brew in current shell
  if [[ "$(uname)" == "Darwin" ]]; then
    if [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed, skipping."
fi

# Install stow
if ! command -v stow &>/dev/null; then
  echo "Installing GNU Stow..."
  brew install stow
else
  echo "GNU Stow already installed, skipping."
fi

# Install zsh (macOS has it by default)
if ! command -v zsh &>/dev/null; then
  echo "Installing Zsh..."
  if command -v dnf &>/dev/null; then
    sudo dnf install -y zsh
  elif command -v apt &>/dev/null; then
    sudo apt install -y zsh
  fi
  echo "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
else
  echo "Zsh already installed, skipping."
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed, skipping."
fi

echo ""
echo "Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Clone dotfiles: git clone git@github.com:<user>/dotfiles.git ~/.dotfiles"
echo "  2. Install dotfiles: cd ~/.dotfiles && ./install.sh"
echo "  3. Install Homebrew packages: brew bundle --global"
echo "  4. Restart shell: exec zsh"
echo ""
echo "Tip: drop machine-local shell functions into ~/.config/zsh/local.d/*.sh"
echo "     (sourced automatically; never committed to this repo)."
echo ""
