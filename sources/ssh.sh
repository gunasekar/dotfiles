#!/bin/bash

##### ssh related functions #####
function ssh-keygen-rsa {
  comment=$1
  if [ -z "$2" ]; then
    ssh-keygen -t rsa -b 4096 -C "$comment"
  else
    ssh-keygen -t rsa -b $2 -C "$comment"
  fi
}

function ssh-keygen-ed25519 {
  comment=$1
  ssh-keygen -t ed25519 -C "$comment"
}

function ssh-keygen-ecdsa {
  comment=$1
  ssh-keygen -t ecdsa -b 521 -C "$comment"
}

# DEPRECATED: DSA keys are no longer secure (max 1024 bits, considered weak)
# Use ssh-keygen-ed25519 or ssh-keygen-rsa instead
function ssh-keygen-dsa {
  echo "⚠️  ERROR: DSA keys are DEPRECATED and INSECURE (max 1024 bits)" >&2
  echo "DSA support has been removed from OpenSSH 7.0+ by default" >&2
  echo "" >&2
  echo "Please use one of these modern alternatives:" >&2
  echo "  • ssh-keygen-ed25519 (RECOMMENDED - fastest and most secure)" >&2
  echo "  • ssh-keygen-rsa (RSA 4096-bit for compatibility)" >&2
  return 1
}

function test-SSH-github {
  ssh -T git@github.com
}

function test-SSH-bitbucket {
  ssh -T git@bitbucket.org
}

function test-SSH-gitlab {
  ssh -T git@gitlab.com
}

##### ghostty terminfo on remote hosts #####
# Replaces Ghostty's built-in `ssh-terminfo` feature, which is disabled in
# ghostty/.config/ghostty/config. Ghostty's version probes the remote with
# `infocmp`, then installs with a bare `tic -x -`. Both consult whichever
# ncurses comes first on PATH. On a host where Homebrew (or any user-local
# ncurses) shadows the system one, that is a terminfo database the login
# shell's ncurses never reads: the probe reports xterm-ghostty present when
# /usr/bin/zsh cannot see it, Ghostty caches the host as done, and every
# session after that runs with TERM=xterm-ghostty against a ZLE that resolved
# no cuu1/cub1/el — so each redraw reprints instead of moving the cursor and
# typing `ls` echoes as `llsls`.
#
# Hence: never probe, and always compile into ~/.terminfo, which every ncurses
# searches and no package manager shadows. Successes are cached below so the
# upload happens once per host.
GHOSTTY_TERMINFO_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-ssh-terminfo"

function ssh {
  # Outside Ghostty there is nothing to install — hand off untouched.
  if [ "$TERM" != "xterm-ghostty" ]; then
    command ssh "$@"
    return
  fi

  local -a opts
  local target term terminfo cdir cpath
  term="xterm-256color"
  opts=(-o "SetEnv COLORTERM=truecolor" -o "SendEnv TERM_PROGRAM TERM_PROGRAM_VERSION")

  # Resolve the real user@host so the cache key survives Host aliases.
  target="$(command ssh -G "$@" 2>/dev/null |
    awk '$1=="user"{u=$2} $1=="hostname"{h=$2} END{if (u&&h) print u"@"h}')"

  if [ -z "$target" ]; then
    command ssh "${opts[@]}" "$@"
    return
  fi

  if grep -qxF "$target" "$GHOSTTY_TERMINFO_CACHE" 2>/dev/null; then
    term="xterm-ghostty"
  elif terminfo="$(infocmp -0 -x xterm-ghostty 2>/dev/null)" && [ -n "$terminfo" ]; then
    cdir="$(mktemp -d "${TMPDIR:-/tmp}/ghostty-ssh.XXXXXX")"
    cpath="$cdir/socket"

    # Open a master connection with -N, so the user authenticates once and the
    # real session below rides the same socket. -N is load-bearing: "$@" may
    # end in a remote command, and without it that command would run here and
    # then AGAIN in the real session.
    if command ssh "${opts[@]}" -f -N -o ControlMaster=yes \
      -o ControlPath="$cpath" -o ControlPersist=60s "$@" 2>/dev/null &&
      printf '%s\n' "$terminfo" |
      command ssh -o ControlPath="$cpath" "$target" '
        command -v tic >/dev/null 2>&1 || exit 1
        mkdir -p "$HOME/.terminfo" && tic -x -o "$HOME/.terminfo" - 2>/dev/null
      ' 2>/dev/null; then
      term="xterm-ghostty"
      opts+=(-o "ControlPath=$cpath")
      mkdir -p "$(dirname "$GHOSTTY_TERMINFO_CACHE")"
      printf '%s\n' "$target" >>"$GHOSTTY_TERMINFO_CACHE"
    else
      rm -f "$cpath" 2>/dev/null
      rmdir "$cdir" 2>/dev/null
      printf 'ssh: could not install xterm-ghostty terminfo on %s, using %s\n' \
        "$target" "$term" >&2
    fi
  fi

  TERM="$term" command ssh "${opts[@]}" "$@"
}
