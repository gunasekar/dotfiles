# ~/.zshenv — sourced by EVERY zsh: login, interactive, scripts, and
# non-interactive shells (zsh -c, cron, git/ssh hooks, Claude Code, …).
#
# RULES for this file:
#   1. Stay SILENT. No echo/printf — stray output corrupts non-interactive
#      protocols like scp/rsync/git-over-ssh.
#   2. Env only. Exports and PATH belong here so they're inherited everywhere.
#      Prompt, bindkey, completion, oh-my-zsh → ~/.zshrc (interactive only).

# ─── Homebrew: detect location, set PATH/MANPATH/INFOPATH ───────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS — ARM (/opt/homebrew) or Intel (/usr/local)
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi
# NOTE: deliberately no `else echo` — .zshenv must never print.

# ─── PATH: personal bins (prepend so they win over system) ──────────────────
export PATH="$HOME/.local/bin:$PATH"

# ─── XDG (used by COLIMA_HOME below and many tools, incl. non-interactive) ───
export XDG_CONFIG_HOME="$HOME/.config"

# ─── Locale ─────────────────────────────────────────────────────────────────
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL=en_US.UTF-8

# ─── Default programs ───────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R"

# ─── Colima / Docker ────────────────────────────────────────────────────────
# Exported here (not in sources/docker.sh) so `docker` works in scripts and
# non-interactive shells too. sources/docker.sh provides the helper *functions*.
# DOCKER_HOST only on macOS — on Linux, native docker uses its own default socket.
export COLIMA_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/colima"
if [[ "$OSTYPE" == "darwin"* ]]; then
  export DOCKER_HOST="unix://${COLIMA_HOME}/default/docker.sock"
fi

# ─── oh-my-zsh: must be set before .zshrc runs compinit ─────────────────────
export ZSH_DISABLE_COMPFIX=true
