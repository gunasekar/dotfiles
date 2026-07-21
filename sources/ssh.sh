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

##### restore terminal state after an interactive ssh session #####
# An abnormal disconnect (timeout, broken pipe, dropped Wi-Fi) kills ssh before
# the remote program can undo the terminal modes it switched on and before the
# remote pty's raw line discipline is handed back. The local terminal keeps
# applying them, so keystrokes arrive as Kitty CSI-u escapes (`c9;1:3u...`) that
# zsh reports as "command not found", and the mouse spews SGR reports
# (`0;16;57M32...`) straight onto the command line.
#
# Only an interactive ssh can leave this mess, so a thin wrapper is the right
# place to clean up: scp, rsync and git-over-ssh allocate no pty and are
# unaffected. Every sequence below is a "disable" form, so running this after a
# session that exited cleanly is a harmless no-op.
function ssh {
  command ssh "$@"
  local ret=$?
  if [[ -t 1 && -t 0 ]]; then
    # mouse tracking off (1000/1002/1003) + SGR mouse off (1006), bracketed
    # paste off (2004), focus reporting off (1004), pop the Kitty keyboard
    # flags the remote pushed (<u), keypad back to normal (\e>), show cursor.
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l\e[?1004l\e[<u\e>\e[?25h'
    stty sane
  fi
  return $ret
}
