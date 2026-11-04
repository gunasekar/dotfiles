#!/usr/bin/env bash
# t → attach-or-create the session named "default".
# Leaves `tmux` untouched for ls, new -s, kill-session, etc.
# Trails workspaces stay separate named sessions; this is only the casual shell.

t() {
  if [[ -n ${TMUX:-} ]]; then
    if command tmux has-session -t default 2>/dev/null; then
      command tmux switch-client -t default
    else
      command tmux new-session -s default
    fi
  else
    command tmux new-session -A -s default
  fi
}
