#!/bin/bash
#
# Fit Mermaid diagrams to the width of Obsidian's Quick Look preview (macOS).
#
# Obsidian renders Mermaid at its natural size (useMaxWidth: false), so a wide
# diagram runs past the preview and scrolls sideways. The preview has no hook
# for user CSS, so this appends a rule to the renderer's own stylesheet.
#
# Obsidian rewrites that stylesheet whenever it updates (a new
# ~/Library/Application Support/obsidian/quicklook/<hash>/), so run this again
# after an Obsidian update. It is safe to run any number of times.
#

css="$HOME/Library/Application Support/obsidian/quicklook/current/quicklook.css"
marker="/* dotfiles: fit mermaid to preview width */"

if [ ! -f "$css" ]; then
  echo "Error: $css not found. Open Obsidian (1.14 or later) once, then rerun."
  exit 1
fi

if grep -qF "$marker" "$css"; then
  echo "ok: already patched"
  exit 0
fi

cat >>"$css" <<EOF

$marker
.markdown-preview-view .mermaid > svg {
  max-width: 100% !important;
  height: auto !important;
}
EOF

# Drop previews Quick Look already rendered with the old stylesheet.
qlmanage -r cache >/dev/null 2>&1
echo "ok: patched $css"
