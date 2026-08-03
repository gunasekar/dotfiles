#!/bin/bash
#
# Default application bindings for file types (macOS LaunchServices).
# Requires duti (in brew/.Brewfile), so run this after `brew bundle --global`.
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

# bind <bundle_id> <uti> <extension-to-verify>
bind() {
  duti -s "$1" "$2" all
  if [ "$(duti -x "$3" 2>/dev/null | sed -n 3p)" = "$1" ]; then
    echo "ok: .$3 -> $1"
  else
    echo "FAILED: .$3 is $(duti -x "$3" 2>/dev/null | sed -n 3p), wanted $1"
    echo "        (check for a Finder dialog waiting to confirm the change)"
    status=1
  fi
}

# Gapplin for SVG. This covers .svgz too — it conforms to public.svg-image, and
# binding public.svgz-image separately is a silent no-op (duti reports success
# but writes nothing), so there is no second line for it.
bind com.wolfrosch.Gapplin public.svg-image svg

exit "$status"
