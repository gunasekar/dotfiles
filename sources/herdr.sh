#!/usr/bin/env bash

# herdr session shortcuts. Local projects and remote (ssh) work live in
# separate persistent sessions so the sidebar never mixes them: `local` gets
# one workspace per local project, `remote` gets one workspace per remote
# host/project (each pane just `ssh`-ing in). Remote host aliases live in
# ~/.ssh/config (dotfiles-private), never hardcoded here.
if command -v herdr &>/dev/null; then
  alias hl='herdr --session local'
  alias hr='herdr --session remote'
fi
