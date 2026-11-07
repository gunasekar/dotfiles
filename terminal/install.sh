#!/bin/bash
#
# Apply the Terminal.app "g9n" profile from this package and make it the
# default. Safe to re-run. macOS only.
#
# Terminal keeps profiles in its preferences domain (not a live-read config
# file), so stow alone is not enough — this script imports/updates the profile
# and sets it as Default + Startup.
#

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "terminal/install.sh: macOS only, skipping"
  exit 0
fi

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
PROFILE_NAME="g9n"
# Prefer the stowed path; fall back to the repo copy before stow has run.
PROFILE_PATH="$HOME/.config/terminal/g9n.terminal"
if [[ ! -f "$PROFILE_PATH" ]]; then
  PROFILE_PATH="$DOTFILES/terminal/.config/terminal/g9n.terminal"
fi

if [[ ! -f "$PROFILE_PATH" ]]; then
  echo "error: profile not found at $PROFILE_PATH" >&2
  exit 1
fi

if [[ ! -f "$HOME/Library/Fonts/HackNerdFontMono-Regular.ttf" ]] &&
  ! fc-list 2>/dev/null | grep -qi 'Hack Nerd Font Mono'; then
  echo "warning: Hack Nerd Font Mono not found — install with:" >&2
  echo "  brew bundle --global   # includes font-hack-nerd-font" >&2
fi

# Merge the exported profile into Terminal's Window Settings, replacing any
# previous "g9n" entry. Also drop the old "Black" / "Black N" names from before
# the g9n rename. Do not `open` the .terminal file here — that spawns a
# window, and auto-closing it trips "terminate running processes: -zsh, env".
# Prefs on disk are enough for the next new window; if Terminal is already
# running, the light AppleScript below retargets Default/Startup without
# opening anything (and may be overwritten when that Terminal quits — open a
# new window or quit once after install if settings look stale).
python3 - "$PROFILE_PATH" "$PROFILE_NAME" <<'PY'
import pathlib, plistlib, sys

profile_path = pathlib.Path(sys.argv[1])
name = sys.argv[2]
prefs_path = pathlib.Path.home() / "Library/Preferences/com.apple.Terminal.plist"

profile = plistlib.loads(profile_path.read_bytes())
profile["name"] = name

if prefs_path.exists():
    with prefs_path.open("rb") as f:
        prefs = plistlib.load(f)
else:
    prefs = {}

windows = prefs.setdefault("Window Settings", {})
windows[name] = profile
# Drop duplicate "g9n 1"/"Black 1" style copies and the pre-rename "Black" profile.
for key in list(windows):
    if key == name:
        continue
    if key.startswith(name + " ") or key == "Black" or key.startswith("Black "):
        del windows[key]
prefs["Default Window Settings"] = name
prefs["Startup Window Settings"] = name

with prefs_path.open("wb") as f:
    plistlib.dump(prefs, f, fmt=plistlib.FMT_BINARY)
print(f"merged profile {name!r} into {prefs_path}")
PY

# Refresh cfprefsd's view of the domain after the direct plist write.
defaults read com.apple.Terminal >/dev/null
defaults write com.apple.Terminal "Default Window Settings" -string "$PROFILE_NAME"
defaults write com.apple.Terminal "Startup Window Settings" -string "$PROFILE_NAME"

# General → New tabs open with → Default Working Directory (the user's home).
defaults write com.apple.Terminal NewTabWorkingDirectoryBehavior -int 1

# Hide the tab bar when there is only one tab. Apple's key really is spelled
# "Shoud". ShowTabBar is the older boolean some docs mention; clear both so a
# prior "always show tab bar" (View → Show Tab Bar) does not stick.
# Note: showing/hiding the bar can change window height when tabs open/close.
defaults write com.apple.Terminal \
  "NSWindowTabbingShoudShowTabBarKey-TTWindow-TTWindowController-TTWindowController-VT-FS" -bool false
defaults write com.apple.Terminal ShowTabBar -bool false

# If Terminal is already running, retarget Default/Startup and hide the tab bar
# without opening a window. Skip entirely when Terminal is not running so install
# never launches it as a side effect.
if pgrep -x Terminal >/dev/null 2>&1; then
  osascript - "$PROFILE_NAME" <<'APPLESCRIPT' || true
on run argv
  set profileName to item 1 of argv
  tell application "Terminal"
    try
      set default settings to settings set profileName
      set startup settings to settings set profileName
      set s to settings set profileName
      set title displays device name of s to false
      set title displays shell path of s to false
      set title displays window size of s to false
      set title displays settings name of s to false
      set title displays custom title of s to false
    end try
  end tell
  try
    tell application "System Events"
      tell process "Terminal"
        if exists (menu item "Hide Tab Bar" of menu "View" of menu bar 1) then
          click menu item "Hide Tab Bar" of menu "View" of menu bar 1
        end if
      end tell
    end tell
  end try
end run
APPLESCRIPT
fi

echo "Terminal.app profile '$PROFILE_NAME' installed and set as default (daily driver)."
echo "  kitty is alternate: Spotlight or \`open -a kitty\`."
echo "  New windows/tabs use g9n; close-on-shell-exit on; tab bar hidden for single tabs."
echo "  New tabs start in the home directory."
echo "  Already-open windows keep their old profile — use Cmd+N (or quit Terminal once)."
echo "  File-type defaults (scripts → TextEdit, not Terminal): setup/macos-file-handlers.sh"
