#!/bin/bash
#
# Default application bindings for file types (macOS LaunchServices).
# Requires duti (in brew/.Brewfile), so run this after `brew bundle --global`.
#
# Policy (double-click = open/view/edit; never execute):
#   - Shell / .command / .tool → TextEdit (run only from a shell on purpose)
#   - Programming & structured text (source, JSON, YAML, TOML, …) → TextEdit
#   - .log → Console.app (plain text viewer for app logs; severity dots are
#     for the system log stream only)
#   - .md → Obsidian when installed
#   - .html → leave to the default web browser (do not rebind here)
#   - Video (public.movie) → mpv.app if present, else QuickTime
#     Note: Homebrew formula `mpv` is CLI-only and cannot be a Finder handler.
#   - SVG → Gapplin if installed, else the default browser (http handler;
#     Preview claims .svg but opens nothing on current macOS)
#   - Raster images → Preview (undo grabby screenshot apps)
#
# Note: duti exits 0 once it has *requested* a change, not once one is applied.
# macOS confirms programmatic default-app changes with a Finder dialog and holds
# the write until you answer it, so a binding can report success and not take
# effect. Every binding below is read back and verified rather than trusted.
#

if ! command -v duti &>/dev/null; then
  echo "Error: duti not installed. Run: brew bundle --global"
  exit 1
fi

status=0

# bind <bundle_id> <uti-or-.ext> <extension-to-verify>
bind() {
  local bundle="$1" target="$2" ext="$3"
  duti -s "$bundle" "$target" all
  if [ "$(duti -x "$ext" 2>/dev/null | sed -n 3p)" = "$bundle" ]; then
    echo "ok: .$ext -> $bundle"
  else
    echo "FAILED: .$ext is $(duti -x "$ext" 2>/dev/null | sed -n 3p), wanted $bundle"
    echo "        (check for a Finder dialog waiting to confirm the change)"
    status=1
  fi
}

TEXTEDIT=com.apple.TextEdit

# --- never execute on open ---------------------------------------------------
bind "$TEXTEDIT" public.shell-script sh
bind "$TEXTEDIT" public.bash-script bash
bind "$TEXTEDIT" com.apple.terminal.shell-script command
bind "$TEXTEDIT" .tool tool
# .zsh usually shares public.shell-script; force-extension if still Terminal.
bind "$TEXTEDIT" .zsh zsh

# --- programming / config text → TextEdit ------------------------------------
bind "$TEXTEDIT" public.source-code c
bind "$TEXTEDIT" public.python-script py
bind "$TEXTEDIT" public.json json
bind "$TEXTEDIT" public.yaml yaml
bind "$TEXTEDIT" .yml yml
bind "$TEXTEDIT" .toml toml
bind "$TEXTEDIT" .js js
bind "$TEXTEDIT" .ts ts
# macOS types .ts as MPEG-2 transport stream; bind that UTI or editors win.
bind "$TEXTEDIT" public.mpeg-2-transport-stream ts
bind "$TEXTEDIT" .jsx jsx
bind "$TEXTEDIT" .tsx tsx
bind "$TEXTEDIT" .go go
bind "$TEXTEDIT" .rs rs
bind "$TEXTEDIT" .java java
bind "$TEXTEDIT" .rb rb
bind "$TEXTEDIT" .php php
bind "$TEXTEDIT" .css css

# --- logs → Console ----------------------------------------------------------
# Sample .log files often declare both public.log and com.apple.log; bind both
# plus the extension so Finder Open doesn't fall back to TextEdit.
bind com.apple.Console public.log log
bind com.apple.Console com.apple.log log
bind com.apple.Console .log log

# --- markdown ----------------------------------------------------------------
if [ -d /Applications/Obsidian.app ]; then
  bind md.obsidian net.daringfireball.markdown md
fi

# --- SVG / images ------------------------------------------------------------
# Gapplin when present; otherwise the default browser (same handler as http /
# public.html). Preview lists .svg but opens zero documents on current macOS.
if [ -d /Applications/Gapplin.app ]; then
  svg_app=com.wolfrosch.Gapplin
else
  svg_app=$(duti -d http 2>/dev/null || true)
  if [ -z "$svg_app" ]; then
    svg_app=com.apple.Safari
  fi
  echo "note: no Gapplin.app — SVG → $svg_app (default browser)"
fi
bind "$svg_app" public.svg-image svg
bind com.apple.Preview public.png png
bind com.apple.Preview public.jpeg jpg

# --- video -------------------------------------------------------------------
# Prefer a real .app named mpv; otherwise stock QuickTime (not Monosnap).
video_app=
if [ -d /Applications/mpv.app ]; then
  video_app=$(osascript -e 'id of app "mpv"' 2>/dev/null || echo io.mpv)
elif [ -d /Applications/IINA.app ]; then
  # Optional mpv-based GUI player if someone installs it
  video_app=$(osascript -e 'id of app "IINA"' 2>/dev/null || echo com.colliderli.iina)
else
  video_app=com.apple.QuickTimePlayerX
  echo "note: no mpv.app (brew formula is CLI-only) — video → QuickTime; play with: mpv <file>"
fi
bind "$video_app" public.mpeg-4 mp4
bind "$video_app" public.movie mov

# HTML: intentionally not bound — stays with the default browser.

exit "$status"
