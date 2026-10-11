#!/usr/bin/env bash

# Keep this Mac awake, from the menu bar.
#
# <swiftbar.title>Keep Awake</swiftbar.title>
# <swiftbar.version>v1.0</swiftbar.version>
# <swiftbar.author>Gunasekaran Namachivayam</swiftbar.author>
# <swiftbar.author.github>gunasekar</swiftbar.author.github>
# <swiftbar.desc>Hold off idle sleep for a set stretch — the Amphetamine replacement</swiftbar.desc>
# <swiftbar.dependencies>keepawake,caffeinate,pmset</swiftbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
#
# All the thinking lives in `keepawake` (bin/.local/bin/keepawake), the same way this
# plugin's neighbour agents.10s.sh defers to `aigent ls`. This file picks four
# durations, draws a cup, and shells out — so the same holds can be started and stopped
# over ssh, which is the entire reason Amphetamine had to go.
#
# ─── Why it always draws something ───────────────────────────────────────────
# agents.10s.sh exits silently when no agent is running, because an icon that is always
# there is one you stop seeing. This one is the opposite and must be: the menu is the
# only way to *start* a hold, so hiding it when nothing is held would hide the button at
# exactly the moment you want it. What changes is the icon — a filled cup when we are
# holding it, a hollow one when something else is (an agent, Claude Code mid-turn), zzz
# when the machine is free to drop off.
#
# ─── The 1m refresh ──────────────────────────────────────────────────────────
# The title is just the cup, but the cup has to change when a hold expires or another holder
# comes and goes, so it re-reads on a timer. A minute is plenty for an icon nobody watches
# tick — a faster poll would spend `pmset -g assertions` every few seconds to redraw the same
# picture. refreshOnOpen covers the case the timer does not: clicking the icon re-reads
# before the menu is built, so the "Stop" row is never offering to cancel a hold that
# expired 40 seconds ago.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

# The absolute path, for agents.10s.sh's reason: SwiftBar runs plugins from launchd, whose
# PATH is not the shell's, so a bare name would be a coin toss regardless of what it is called.
KEEPAWAKE="${HOME}/.dotfiles/bin/.local/bin/keepawake"
[ -x "$KEEPAWAKE" ] || exit 0

SCRIPT_PATH="$(realpath -q "$0")"

COFFEE='#a67b5b' # the filled cup — our hold; mid-brown so it reads on a dark or light bar
DIM='#5c6370'    # the hollow cup — someone else's hold — and the two submenu headers

# ─── Actions (SwiftBar re-runs this file with the function name as param1) ───
function hold30m() { "$KEEPAWAKE" 30m; }
function hold1h() { "$KEEPAWAKE" 1h; }
function hold6h() { "$KEEPAWAKE" 6h; }
function hold12h() { "$KEEPAWAKE" 12h; }
function holdOn() { "$KEEPAWAKE" on; }
function holdOff() { "$KEEPAWAKE" off; }

[[ $# -ge 1 ]] && { $1 && exit $?; }

# ─── State ───────────────────────────────────────────────────────────────────
# `keepawake status` down a pipe is TSV: one optional `own` row (seconds left, or "-" when
# open-ended) and an `other` row per outside holder. No rows at all means nothing is
# holding the machine awake.
own=''
label=''
others=()
while IFS=$'\t' read -r kind a b; do
  case "$kind" in
    own) own="$a" label="$b" ;;
    other) others+=("${a}|${b}") ;;
  esac
done < <("$KEEPAWAKE" status)

# 21480 → "5h58m". Tighter than keepawake's own human_secs, because this one is competing
# for menu bar width with a clock and everything else up there.
function compact() {
  local s=$1
  if ((s >= 3600)); then
    printf '%dh%02dm' $((s / 3600)) $(((s % 3600) / 60))
  elif ((s >= 60)); then
    printf '%dm' $((s / 60))
  else
    printf '%ds' "$s"
  fi
}

function createAction() {
  echo "$1 | bash='${SCRIPT_PATH}' param1=$2 terminal=false refresh=true"
}

# ─── Title ───────────────────────────────────────────────────────────────────
# Icon only: the cup's state is the whole message — filled, we are holding it; hollow,
# something else is; zzz, nothing is. How long is left is a click away in the menu, and a
# countdown in the bar was width spent on a number you rarely need at a glance.
#
# Coloured through sfconfig, because SwiftBar ignores sfcolor on a menu-bar sfimage (it only
# takes colours from sfconfig — see mmi.30m.sh). No "scale" in it, which SwiftBar reads as
# large: the same size as an unconfigured icon. zzz is left uncoloured on purpose, a plain
# template that follows the bar's light/dark, since "nothing is happening" should not draw
# the eye.
tint() { printf '{"renderingMode":"Palette","colors":["%s"]}' "$1" | base64 | tr -d '\n'; }
if [[ -n $own ]]; then
  echo " | sfimage=cup.and.saucer.fill sfconfig=$(tint "$COFFEE")"
elif ((${#others[@]})); then
  echo " | sfimage=cup.and.saucer sfconfig=$(tint "$DIM")"
else
  echo " | sfimage=zzz"
fi

echo "---"

# ─── Menu ────────────────────────────────────────────────────────────────────
if [[ -n $own ]]; then
  if [[ $own == '-' ]]; then
    echo "Awake until stopped"
  else
    # The wake-until clock, because "5h58m left" and "up till 21:54" answer different
    # questions and the second one is the one you ask before walking away.
    echo "Awake for $(compact "$own") more, till $(date -v+"${own}"S +%H:%M)"
  fi
  createAction "Stop keeping awake" holdOff
  echo "---"
fi

# The two submenu parents ("Keep awake for", "Also held by") keep their color=, and it is
# load-bearing rather than decoration. SwiftBar 2.1.0–2.1.1 greys out an *actionless* submenu
# parent for the rest of the session the moment its child count changes (swiftbar/SwiftBar
# #512, #514, #515 — "Also held by" changes size whenever a holder comes or goes). A line with
# a color is owned by SwiftBar's own handler and escapes that path, so these stayed usable
# for exactly as long as they were coloured. Fixed upstream in 2.1.2 (#518); drop the colour
# only once that release is installed.
echo "Keep awake for | color=${DIM}"
createAction "-- 30 minutes" hold30m
createAction "-- 1 hour" hold1h
createAction "-- 6 hours" hold6h
createAction "-- 12 hours" hold12h
createAction "-- Until I stop it" holdOn

# Anything else holding the machine up, named by what it is holding it *for* rather than
# by "caffeinate" — which is what all of them are, and so tells you nothing. Listed because
# without it the icon is a hollow cup with no explanation, and because it is the honest
# answer to "why has this thing not gone to sleep": frequently an agent you left running,
# which is the ctrl-a launch in `aigent`.
if ((${#others[@]})); then
  echo "---"
  echo "Also held by | color=${DIM}"
  for entry in "${others[@]}"; do
    echo "-- ${entry#*|}  (pid ${entry%%|*})"
  done
fi
