#!/usr/bin/env bash

function n {
  if ! command -v nvim &>/dev/null; then
    echo "nvim not found. please install neovim"
    return 1
  fi
  nvim "${@:-.}"
}

# `aigent` (~/.local/bin/aigent, see bin/ package) is the same fzf picker used
# by nvim's right panel and Zed's agent.terminal_init_command — a real
# command rather than an alias so it also works from scripts and
# non-interactive shells.
#
# It is `aigent` and not `agent` because ~/.local/bin is a shared namespace: every CLI
# installer drops binaries there, and cursor-agent ships one called `agent` that
# overwrote our symlink on install *and on every self-update*, silently turning
# `agent` into Cursor's CLI. `agent` is a name vendors want; `aigent` is not.

# Lazy tool aliases
command -v lazygit &>/dev/null && alias gitl='lazygit'
command -v lazydocker &>/dev/null && alias dockerl='lazydocker'

# direnv hook
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
