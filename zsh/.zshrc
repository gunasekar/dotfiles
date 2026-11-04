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
setopt HIST_IGNORE_DUPS  # don't store consecutive duplicates
setopt HIST_IGNORE_SPACE # don't store commands prefixed with a space
setopt HIST_VERIFY       # expand history before executing
setopt SHARE_HISTORY     # share history across all open shells
setopt EXTENDED_HISTORY  # save timestamp + duration with each entry

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
  bindkey "^[[1;3C" forward-word  # Option + Right Arrow
  bindkey "^[[1;3D" backward-word # Option + Left Arrow
  # kitty sends these in CSI-u form so they survive tmux (see kitty.conf).
  bindkey "^[[13;2u" accept-line # Shift + Enter runs the line, as Enter
  bindkey "^[[27;5u" redisplay   # Ctrl + Esc does nothing
  bindkey "^[[92;6u" redisplay   # Ctrl + Shift + \ does nothing
  bindkey "^[[91;6u" redisplay   # Ctrl + Shift + [ does nothing
  bindkey "^[[93;6u" redisplay   # Ctrl + Shift + ] does nothing
  bindkey "^[[46;6u" redisplay   # Ctrl + Shift + . does nothing
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

# Prompt + terminal/tmux pane titles (after sources so DEFAULT_USER is set).
# Local as DEFAULT_USER: cwd only (or the running command — oh-my-zsh termsupport).
# SSH or another user: user@host:cwd — common when ssh → probochs → trails/tmux (#T).
if [[ -n "${SSH_CONNECTION:-}" || (-n "${DEFAULT_USER:-}" && "$USER" != "$DEFAULT_USER") ]]; then
  PROMPT="%{$fg_bold[green]%}%n@%m %(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg[cyan]%}%c%{$reset_color%}"
  PROMPT+=' $(git_prompt_info)'
  ZSH_THEME_TERM_TITLE_IDLE="%n@%m:%~"
  ZSH_THEME_TERM_TAB_TITLE_IDLE="%n@%m:%~"
else
  ZSH_THEME_TERM_TITLE_IDLE="%~"
  ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%~%<<"
fi

# Terminal.app: set only OSC ]2; clear ]1 so the tab doesn't join "]1 — ]2".
# g9n profile leaves title checkboxes off, so the shell owns both places.
if [[ "$TERM_PROGRAM" == Apple_Terminal ]]; then
  title() {
    setopt localoptions nopromptsubst
    [[ -n "${INSIDE_EMACS:-}" && "$INSIDE_EMACS" != vterm ]] && return
    : ${2=$1}
    print -Pn "\e]2;${2:q}\a" # window / tmux pane title
    print -Pn "\e]1;\a"       # clear tab title — avoids ]1+]2 em-dash join
  }
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
