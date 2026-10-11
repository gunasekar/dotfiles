#!/usr/bin/env bash

function n {
  if ! command -v nvim &>/dev/null; then
    echo "nvim not found. please install neovim"
    return 1
  fi
  nvim "${@:-.}"
}

# `trails` (github.com/gunasekar/trails, `brew "gunasekar/tap/trails"` in the
# Brewfile) is the same fzf picker used by nvim's right panel and Zed's
# agent.terminal_init_command — a real command rather than an alias so it also
# works from scripts and non-interactive shells.

# Lazy tool aliases
command -v lazygit &>/dev/null && alias gitl='lazygit'
command -v lazydocker &>/dev/null && alias dockerl='lazydocker'

# direnv hook
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
