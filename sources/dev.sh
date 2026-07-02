#!/usr/bin/env bash


function n {
    if ! command -v nvim &>/dev/null; then
        echo "nvim not found. please install neovim"
        return 1
    fi
    nvim "${@:-.}"
}

# `agent` (~/.local/bin/agent, see bin/ package) is the same fzf picker used
# by nvim's right panel and Zed's agent.terminal_init_command — a real
# command rather than an alias so it also works from scripts and
# non-interactive shells. CLI installers (cursor-agent, grok, ...) also
# write to ~/.local/bin/agent and may clobber this symlink on install/update
# — if `agent` stops launching the picker, re-run install.sh (or `stow bin`
# from ~/.dotfiles) to restore it.

# Lazy tool aliases
command -v lazygit &>/dev/null && alias gitl='lazygit'
command -v lazydocker &>/dev/null && alias dockerl='lazydocker'

# direnv hook
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
