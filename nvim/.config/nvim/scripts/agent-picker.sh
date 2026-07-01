#!/usr/bin/env sh
# Agent picker for the right-panel agent terminal (nvim) and Zed's
# agent.terminal_init_command. Add entries to AGENTS + the case below to
# expose more agents/personas.
AGENTS='default
plan
explore
cursor-agent'

# height = prompt row + top/bottom borders + one row per entry
height=$(($(printf '%s\n' "$AGENTS" | wc -l) + 3))

choice=$(printf '%s\n' "$AGENTS" | fzf --prompt='Agent: ' --height="$height" --reverse --no-info) || exit 0
case "$choice" in
  plan) exec claude --agent Plan --model opus ;;
  explore) exec claude --agent Explore --model sonnet ;;
  cursor-agent) exec cursor-agent ;;
  default | *) exec claude ;;
esac
