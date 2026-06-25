# PATH, XDG, locale, EDITOR, and Colima/Docker env now live in ~/.zshenv so
# they're available to scripts and non-interactive shells too — not just here.
# This file is interactive-only: oh-my-zsh, prompt, keybindings, function libs.

# DEFAULT_USER is set in private dotfiles (sources/dev.sh) to hide user@host
# in the prompt when logged in as the primary user locally.

# ─── History ────────────────────────────────────────────────────────────────
# Set before Oh My Zsh loads so these values take precedence over its defaults.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_DUPS       # don't store consecutive duplicates
setopt HIST_IGNORE_SPACE      # don't store commands prefixed with a space
setopt HIST_VERIFY            # expand history before executing
setopt SHARE_HISTORY          # share history across all open shells
setopt EXTENDED_HISTORY       # save timestamp + duration with each entry

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Emacs-style line editing + Option-arrow word jumps (interactive only).
# Moved here from .zshenv — bindkey is meaningless in non-interactive shells.
if [[ "$OSTYPE" == darwin* ]]; then
  bindkey -e
  bindkey "^[[1;3C" forward-word    # Option + Right Arrow
  bindkey "^[[1;3D" backward-word   # Option + Left Arrow
fi

# Source every *.sh in a directory. Missing dir → silently skip (so optional
# drop-in locations are safe and stay quiet in non-interactive shells).
source_all_in_directory() {
    local dir="$1"
    [ -d "$dir" ] || return 0

    for file in "$dir"/*.sh; do
        if [ -f "$file" ] && [ -r "$file" ]; then
            source "$file"
        fi
    done
}

# This repo's own function library.
source_all_in_directory "$HOME/.dotfiles/sources"

# Optional machine-local / private overrides. Drop *.sh files into this dir
# (or symlink it elsewhere) to extend the shell without touching this repo.
# It does not exist by default — nothing here depends on it.
source_all_in_directory "${ZSH_LOCAL_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.d}"

# Show user@host when in SSH session or running as different user.
# Runs after sources so DEFAULT_USER (set in private dotfiles) is available.
if [[ -n "$SSH_CONNECTION" || "$USER" != "$DEFAULT_USER" ]]; then
  PROMPT="%{$fg_bold[green]%}%n@%m %(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg[cyan]%}%c%{$reset_color%}"
  PROMPT+=' $(git_prompt_info)'
fi

export GPG_TTY=$(tty)
gpgconf --launch gpg-agent

alias refreSH="exec $SHELL -l"

# ─── Brew-sourced zsh plugins (no git clones needed) ────────────────────────
if command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  [[ -d "$BREW_PREFIX/share/zsh-completions" ]] && FPATH="$BREW_PREFIX/share/zsh-completions:$FPATH"
  [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

