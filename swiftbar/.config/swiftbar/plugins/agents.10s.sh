#!/usr/bin/env bash

# Agents that want you back, in the menu bar.
#
# <swiftbar.title>Agents</swiftbar.title>
# <swiftbar.version>v1.0</swiftbar.version>
# <swiftbar.desc>Which tmux agent sessions are blocked, waiting, or working</swiftbar.desc>
# <swiftbar.dependencies>tmux,aigent</swiftbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
#
# The picker (`aigent`) only tells you when you go and look, and it is scoped to the
# project you are standing in. This is the other half: every agent on the box, polled,
# whether or not you are looking — the "what did I leave running while I walked away"
# view. All the thinking lives in `aigent status`, which decides blocked/waiting/working
# by diffing each session's screen (see tmux/README.md); this file only renders it.
#
# It emits nothing at all when no agent is running, which is how SwiftBar is told to
# hide the menu bar item entirely — a dot that is always there is a dot you stop seeing.
#
# ─── Why it waits before saying anything ─────────────────────────────────────
# It does not announce "finished". It announces "*still* waiting, a minute later".
#
# Announcing the working → stopped edge itself is what a notifier obviously wants to
# do, and it is wrong: an agent you are sitting in front of crosses that edge at the
# end of every single turn. You get a popup telling you the thing you are looking at
# has stopped — once per reply, forever. That is not a notification, it is a metronome.
#
# There is no way to ask tmux whether you are *looking* at a session. Every session has
# a client attached (a Ghostty window, a Zed thread, an nvim panel), so attachment says
# nothing. #{client_activity} is genuinely useful — it tracks your keystrokes and not
# pane output, verified: it did not move once through 48s of an agent painting flat out
# — but it answers "when did you last type", and after a three-minute turn that reads
# the same whether you are staring at the pane or asleep.
#
# What separates the two is what you do *next*. Sitting there, you reply in seconds and
# it goes back to working. Walked away, it just sits there. So: wait GRACE seconds, and
# only speak if it is still stopped. Being there silences it for free — no focus
# detection, no heuristic, nothing to get wrong — and walking away is the only thing
# that lets it through. It also means any future misclassification has to persist for a
# full minute before it can reach you.
#
# The menu bar itself updates immediately; only the popup waits.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

# The absolute path, like nvim's AGENT_CMD and Zed's terminal_init_command — SwiftBar
# runs plugins from launchd, whose PATH is not the shell's, so a bare name would be a
# coin toss regardless of what it is called.
AIGENT="${HOME}/.dotfiles/bin/.local/bin/aigent"
[ -x "$AIGENT" ] || exit 0

ROWS=$("$AIGENT" status 2>/dev/null)
[ -n "$ROWS" ] || exit 0

RED='#e06c75'    # blocked — it is asking you something
YELLOW='#e5c07b' # waiting — it finished its turn, your move
DIM='#5c6370'    # working — leave it alone

# How long an agent has to sit there wanting you before it is allowed to say so.
# Long enough that you never hear from one you are actually working with, short enough
# to be useful the moment you are not.
GRACE=${AGENT_NOTIFY_AFTER:-60}
NOW=$(date +%s)

# One line per session: name, state, when it entered that state, whether it has been
# seen working (so a session that was already idle when the plugin first saw it is not
# announced — that is not news), and whether we have already spoken about this episode.
STATE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/aigent"
STATE_FILE="${STATE_DIR}/swiftbar-state"
mkdir -p "$STATE_DIR"
PREV=$(cat "$STATE_FILE" 2>/dev/null)
: >"${STATE_FILE}.new"

# The task text is written by the agent, not by us: it lands in an AppleScript string
# literal, so quotes and backslashes have to go or the script fails to compile.
clean() { printf '%s' "${1//[\"\\]/}"; }

notify() {
  osascript -e "display notification \"$(clean "$2")\" with title \"$(clean "$1")\"" \
    >/dev/null 2>&1 || true
}

blocked=0 waiting=0 working=0
menu=''

while IFS=$'\t' read -r state name agent task; do
  [ -n "$name" ] || continue

  # aigent-my_api-2  ->  project "my_api", badge "#2". A project name may itself contain
  # a dash, so only a *trailing* -<digits> is the sibling counter.
  proj=${name#aigent-}
  badge=''
  if [[ $proj =~ ^(.*)-([0-9]+)$ ]]; then
    proj="${BASH_REMATCH[1]}"
    badge=" #${BASH_REMATCH[2]}"
  fi

  case $state in
    blocked)
      colour=$RED
      ((blocked++))
      ;;
    waiting)
      colour=$YELLOW
      ((waiting++))
      ;;
    *)
      colour=$DIM
      ((working++))
      ;;
  esac

  line="● ${state} · ${agent} · ${proj}${badge}"
  [ -n "$task" ] && line+=" — ${task}"
  menu+="${line//|/－} | color=${colour} font=Menlo size=12"$'\n'

  # What we knew about this session last poll (all empty the first time we see it).
  IFS=$'\t' read -r p_state p_since p_seen p_said < <(
    printf '%s\n' "$PREV" | awk -F'\t' -v n="$name" '$1 == n { print $2 "\t" $3 "\t" $4 "\t" $5; exit }'
  )

  if [ "$state" = working ]; then
    # Working resets everything: it has now been seen working, so the next time it
    # stops that is a real episode, and it has not been spoken about yet.
    since=$NOW seen=1 said=0
  else
    if [ "$state" = "$p_state" ]; then
      # Still in the same stopped state — keep counting from when it got here.
      since=${p_since:-$NOW} seen=${p_seen:-0} said=${p_said:-0}
    else
      # Just arrived in this state. waiting -> blocked is a new thing to say, so the
      # clock and `said` both reset, but `seen` carries over.
      since=$NOW said=0
      seen=${p_seen:-0}
      [ "$p_state" = working ] && seen=1
    fi

    if [ "$seen" = 1 ] && [ "$said" = 0 ] && [ $((NOW - since)) -ge "$GRACE" ]; then
      mins=$(((NOW - since) / 60))
      if [ "$state" = blocked ]; then
        notify "${agent} needs you · ${proj}" "${task:-Waiting on a permission prompt}"
      else
        notify "${agent} idle ${mins}m · ${proj}" "${task:-Finished — waiting for your next move}"
      fi
      said=1
    fi
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$state" "$since" "$seen" "$said" >>"${STATE_FILE}.new"
done <<<"$ROWS"

mv -f "${STATE_FILE}.new" "$STATE_FILE"

# Menu bar: how many want you, coloured by the worst of them. When they are all busy
# there is nothing to act on, so it shows a dim count rather than an alarm.
want=$((blocked + waiting))
if [ "$blocked" -gt 0 ]; then
  echo "●${want} | color=${RED}"
elif [ "$waiting" -gt 0 ]; then
  echo "●${want} | color=${YELLOW}"
else
  echo "●${working} | color=${DIM}"
fi

echo '---'
printf '%s' "$menu"
echo '---'
echo "${blocked} blocked · ${waiting} waiting · ${working} working | color=${DIM} size=11"
echo "Refresh | refresh=true"
