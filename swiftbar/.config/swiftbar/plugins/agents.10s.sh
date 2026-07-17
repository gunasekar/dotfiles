#!/usr/bin/env bash

# Agents that want you back, in the menu bar.
#
# <swiftbar.title>Agents</swiftbar.title>
# <swiftbar.version>v1.0</swiftbar.version>
# <swiftbar.desc>Which tmux agent sessions are blocked, idle, or working</swiftbar.desc>
# <swiftbar.dependencies>tmux,aigent,jq</swiftbar.dependencies>
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
# view. All the thinking lives in `aigent status`, which decides blocked/idle/working
# by diffing each session's screen (see tmux/README.md); this file only renders it.
#
# It emits nothing at all when no agent is running, which is how SwiftBar is told to
# hide the menu bar item entirely — a dot that is always there is a dot you stop seeing.
#
# ─── When it speaks ──────────────────────────────────────────────────────────
# It announces the working → stopped edge, on the poll that sees it.
#
# The cost is known and accepted: an agent you are sitting in front of crosses that
# edge at the end of every single turn, so you hear about the one you are looking at —
# once per reply. Nothing here can tell the difference. There is no way to ask tmux
# whether you are *looking* at a session: every session has a client attached (a Ghostty
# window, a Zed thread, an nvim panel), so attachment says nothing, and #{client_activity}
# — which does track your keystrokes and not pane output, verified: it did not move once
# through 48s of an agent painting flat out — answers "when did you last type", which
# after a three-minute turn reads the same whether you are staring at the pane or asleep.
#
# The lever that does work is time, and it is the only one. Sitting there, you reply in
# seconds and it goes back to working; walked away, it just sits. So waiting before
# speaking silences the session you are working with for free — no focus detection, no
# heuristic, nothing to get wrong — and it makes any future misclassification persist
# for the whole wait before it can reach you. What it costs is the wait itself, spent on
# the one case this exists for. AGENT_NOTIFY_AFTER is that dial, in seconds; 60 was the
# old default and is a reasonable place to put it back if the per-reply sound wears thin.
#
# `said` bounds it either way: one banner per stop, however many times the screen is
# re-read. Only a return to working re-arms it.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

# The absolute path, like nvim's AGENT_CMD and Zed's terminal_init_command — SwiftBar
# runs plugins from launchd, whose PATH is not the shell's, so a bare name would be a
# coin toss regardless of what it is called.
AIGENT="${HOME}/.dotfiles/bin/.local/bin/aigent"
[ -x "$AIGENT" ] || exit 0

ROWS=$("$AIGENT" status 2>/dev/null)
[ -n "$ROWS" ] || exit 0

RED='#e06c75'    # blocked — it is asking you something
YELLOW='#e5c07b' # idle — it finished its turn, your move
DIM='#5c6370'    # working — leave it alone

# How long an agent has to sit there wanting you before it is allowed to say so.
# Zero: the poll that sees it stop is the poll that says so. Set AGENT_NOTIFY_AFTER to
# trade that latency back for quiet — see the note above.
GRACE=${AGENT_NOTIFY_AFTER:-0}
NOW=$(date +%s)

# One line per session: name, state, when it entered that state, whether it has been
# seen working (so a session that was already idle when the plugin first saw it is not
# announced — that is not news), and whether we have already spoken about this episode.
STATE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/aigent"
STATE_FILE="${STATE_DIR}/swiftbar-state"
mkdir -p "$STATE_DIR"
PREV=$(cat "$STATE_FILE" 2>/dev/null)
: >"${STATE_FILE}.new"

# Posted by SwiftBar itself rather than by osascript, which delivered them as "Script
# Editor" — an app nobody chose, sharing a bucket with every other script on the machine,
# so tuning or muting agent alerts meant tuning every AppleScript you own. SwiftBar tags
# each notification with threadIdentifier = this plugin, so Notification Center collapses
# the pile into one "Agents" group, and clicking through has somewhere to go.
#
# It cannot clear the previous one. swiftbar://notify accepts no identifier, and SwiftBar
# stamps every request with a fresh UUID (v2.0.1, PluginManger.swift:374), so "replace
# what this session said last time" is not expressible through this API at all — six
# finishes leave six entries in the group. Only the *banner* is bounded, by `said` below:
# one per stop, however the screen is re-read.
#
# No silent=true, so these make a sound — the osascript they replaced never did, because
# `display notification` is mute unless asked. A banner is Temporary by default: it shows
# for a few seconds and is gone, which is no use to the one case this exists for, where
# you are not at the screen. The sound is the part that survives not looking.
#
# Which also makes it the part that grates. `said` below holds it to one per stop, but
# with no wait configured a stop is every turn-end, so on a session you are sitting in
# it sounds once per reply — see the note up top. Muting it is at least a per-app toggle
# now that it is SwiftBar's own notification, rather than silencing every AppleScript on
# the machine, which is what the old shared "Script Editor" identity would have meant.
#
# jq's @uri, not hand-rolled escaping: the title and the agent's own task text are being
# pasted into a URL, and the task is arbitrary prose. A bare & truncates the notification
# at the ampersand and a bare # drops the rest, both silently. @uri also gets multi-byte
# right (· and — survive), which a byte-wise shell loop would mangle.
#
# One thing encoding cannot save: SwiftBar rewrites "+" back to a space on the way out,
# so a task title containing a plus loses it. Cosmetic, and not ours to fix.
urlenc() { printf '%s' "$1" | jq -sRr @uri; }

notify() { # title, body
  open -g "swiftbar://notify?name=agents&title=$(urlenc "$1")&body=$(urlenc "$2")" \
    >/dev/null 2>&1 || true
}

blocked=0 idle=0 working=0
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

  # `aigent status` owns these names, and *) means working — so a state it grows that this
  # does not know lands in the "leave it alone" pile rather than raising a false alarm.
  # The cost of that default is that renaming one there fails silently here: the arm stops
  # matching, and every agent that wants you is counted as busy and left unannounced. The
  # two files have to move together.
  case $state in
    blocked)
      colour=$RED
      ((blocked++))
      ;;
    idle)
      colour=$YELLOW
      ((idle++))
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
    case $p_state in
      working)
        # The edge this notifier exists for: it was working, now it is not.
        since=$NOW seen=1 said=0
        ;;
      '')
        # First sight, and already stopped. We never saw it finish, so there is no
        # episode to announce — seen=0 keeps it quiet until it works and stops again.
        since=$NOW seen=0 said=0
        ;;
      *)
        # Stopped -> stopped, which includes idle <-> blocked. Carry the clock and the
        # guard straight across it.
        #
        # Those two are not two events. They are one motionless screen read twice, and
        # which name it gets is decided by grepping whatever text happens to occupy the
        # bottom 15 lines — so a flip means the text moved, not that the agent did
        # anything. It is a guess by construction (aigent's own comment calls it "the one
        # heuristic"), and it is wrong often enough to matter: any agent that merely
        # prints the words "Do you want" reads as blocked while it sits there idle.
        #
        # Resetting `said` here announced one stop twice — once as idle, again as
        # blocked — for a screen that never changed. Only working re-arms.
        since=${p_since:-$NOW} seen=${p_seen:-0} said=${p_said:-0}
        ;;
    esac

    if [ "$seen" = 1 ] && [ "$said" = 0 ] && [ $((NOW - since)) -ge "$GRACE" ]; then
      if [ "$state" = blocked ]; then
        notify "${agent} needs you · ${proj}" "${task:-Waiting on a permission prompt}"
      else
        notify "${agent} idle · ${proj}" "${task:-Finished — waiting for your next move}"
      fi
      said=1
    fi
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$state" "$since" "$seen" "$said" >>"${STATE_FILE}.new"
done <<<"$ROWS"

mv -f "${STATE_FILE}.new" "$STATE_FILE"

# Menu bar: how many want you, coloured by the worst of them. When they are all busy
# there is nothing to act on, so it shows a dim count rather than an alarm.
want=$((blocked + idle))
if [ "$blocked" -gt 0 ]; then
  echo "●${want} | color=${RED}"
elif [ "$idle" -gt 0 ]; then
  echo "●${want} | color=${YELLOW}"
else
  echo "●${working} | color=${DIM}"
fi

echo '---'
printf '%s' "$menu"
echo '---'
echo "${blocked} blocked · ${idle} idle · ${working} working | color=${DIM} size=11"
echo "Refresh | refresh=true"
