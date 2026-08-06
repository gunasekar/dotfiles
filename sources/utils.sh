#!/usr/bin/env bash

##### functions
function setHostName {
  scutil --set ComputerName "$1"
  scutil --set LocalHostName "$1"
  scutil --set HostName "$1"
}

### brew configuration
function set-permissions-for-brew {
  sudo chown -R $(whoami) $(brew --prefix)/*
}

# Shared helper: dump current brew state, extract entries, compute diffs.
# Sets BREW_DIFF_DIR to a temp directory containing:
#   dump, dump_entries, curated_entries, {dump,curated}_{tap,brew,cask,mas}
#   new_{tap,brew,cask,mas}, missing_{tap,brew,cask,mas}, untrusted_{brew,cask}
# Caller is responsible for cleaning up BREW_DIFF_DIR.
function _brew_diff {
  if ! command -v brew &>/dev/null; then
    echo "Error: brew is not installed" >&2
    return 1
  fi

  BREW_DIFF_BREWFILE="${HOMEBREW_BUNDLE_FILE:-$HOME/.Brewfile}"
  if [ ! -f "$BREW_DIFF_BREWFILE" ]; then
    echo "Error: Brewfile not found at $BREW_DIFF_BREWFILE" >&2
    return 1
  fi

  local current_os
  if [[ "$OSTYPE" == darwin* ]]; then
    current_os="mac"
  else
    current_os="linux"
  fi

  BREW_DIFF_DIR=$(mktemp -d)

  echo -e "\033[1mbrew:\033[0m Dumping current brew state..."
  if ! brew bundle dump --no-vscode --file="$BREW_DIFF_DIR/dump" 2>/dev/null; then
    echo "Error: brew bundle dump failed" >&2
    rm -rf "$BREW_DIFF_DIR"
    return 1
  fi

  # Extract type\tname pairs, filtering OS-conditional blocks in curated Brewfile.
  # mas entries carry their numeric App Store id rather than the display name:
  # names may contain spaces ("Windows App"), drift between releases, and are not
  # what `mas install` accepts. The id -> name mapping is kept aside for display.
  : >"$BREW_DIFF_DIR/mas_names"
  _brew_extract() {
    local file="$1" filter="${2:-none}"
    awk -v os="$current_os" -v filter="$filter" -v names="$BREW_DIFF_DIR/mas_names" '
            BEGIN { skip = 0 }
            filter == "os" && /^if OS\.mac\?/  { skip = (os != "mac");  next }
            filter == "os" && /^if OS\.linux\?/ { skip = (os != "linux"); next }
            filter == "os" && /^end$/           { skip = 0; next }
            skip { next }
            /^[[:space:]]*(tap|brew|cask|mas)[[:space:]]+"[^"]+"/ {
                line = $0
                gsub(/^[[:space:]]+/, "", line)
                split(line, a, /[[:space:]]+/)
                type = a[1]
                match($0, /"[^"]+"/)
                name = substr($0, RSTART + 1, RLENGTH - 2)
                if (type == "mas") {
                    if (!match($0, /id:[[:space:]]*[0-9]+/)) next
                    id = substr($0, RSTART, RLENGTH)
                    sub(/id:[[:space:]]*/, "", id)
                    print id "\t" name >> names
                    print type "\t" id
                    next
                }
                print type "\t" name
            }
        ' "$file" | sort -u
  }

  echo -e "\033[1mbrew:\033[0m Comparing against curated Brewfile..."

  _brew_extract "$BREW_DIFF_DIR/dump" none >"$BREW_DIFF_DIR/dump_entries"
  _brew_extract "$BREW_DIFF_BREWFILE" os >"$BREW_DIFF_DIR/curated_entries"
  unset -f _brew_extract

  # Load machine-local ignore list (~/.Brewfile.ignore) — packages to exclude from EXTRA
  local ignore_file="$HOME/.Brewfile.ignore"
  local ignore_entries=""
  if [ -f "$ignore_file" ]; then
    ignore_entries=$(grep -v '^\s*#' "$ignore_file" | grep -v '^\s*$' | sort -u)
  fi

  local type
  for type in tap brew cask mas; do
    grep "^${type}	" "$BREW_DIFF_DIR/dump_entries" | cut -f2 >"$BREW_DIFF_DIR/dump_${type}" 2>/dev/null || true
    grep "^${type}	" "$BREW_DIFF_DIR/curated_entries" | cut -f2 >"$BREW_DIFF_DIR/curated_${type}" 2>/dev/null || true
    comm -23 "$BREW_DIFF_DIR/dump_${type}" "$BREW_DIFF_DIR/curated_${type}" >"$BREW_DIFF_DIR/new_${type}_raw" 2>/dev/null || true
    comm -13 "$BREW_DIFF_DIR/dump_${type}" "$BREW_DIFF_DIR/curated_${type}" >"$BREW_DIFF_DIR/missing_${type}" 2>/dev/null || true
    # Filter ignored packages from EXTRA list
    if [ -n "$ignore_entries" ]; then
      grep -vxFf <(printf '%s\n' "$ignore_entries") "$BREW_DIFF_DIR/new_${type}_raw" >"$BREW_DIFF_DIR/new_${type}" 2>/dev/null || true
    else
      cp "$BREW_DIFF_DIR/new_${type}_raw" "$BREW_DIFF_DIR/new_${type}" 2>/dev/null || true
    fi
  done

  # Homebrew refuses to load formulae from untrusted taps, and `brew bundle dump`
  # drops them without a word — so an installed package looks uninstalled here,
  # and the install we would offer is a silent no-op. Anything we are about to
  # call missing gets cross-checked against what is really installed.
  local installed_list
  for type in brew cask; do
    : >"$BREW_DIFF_DIR/untrusted_${type}"
    [ -s "$BREW_DIFF_DIR/missing_${type}" ] || continue
    case "$type" in
      brew) installed_list=$(brew list --formula 2>/dev/null) ;;
      cask) installed_list=$(brew list --cask 2>/dev/null) ;;
    esac
    : >"$BREW_DIFF_DIR/missing_${type}_checked"
    while IFS= read -r pkg; do
      # Brewfile names third-party packages tap/owner/name; brew list prints name
      if printf '%s\n' "$installed_list" | grep -qxF "${pkg##*/}"; then
        echo "$pkg" >>"$BREW_DIFF_DIR/untrusted_${type}"
      else
        echo "$pkg" >>"$BREW_DIFF_DIR/missing_${type}_checked"
      fi
    done <"$BREW_DIFF_DIR/missing_${type}"
    mv "$BREW_DIFF_DIR/missing_${type}_checked" "$BREW_DIFF_DIR/missing_${type}"
  done
}

# mas entries are tracked by App Store id, which reads as noise on its own.
# Print "Name (id)" where a name is known, and the bare entry for every other type.
function _brew_label {
  local type="$1" pkg="$2" name
  if [ "$type" = "mas" ]; then
    name=$(grep -m1 "^${pkg}	" "$BREW_DIFF_DIR/mas_names" 2>/dev/null | cut -f2)
    [ -n "$name" ] && printf '%s (%s)' "$name" "$pkg" && return
  fi
  printf '%s' "$pkg"
}

# mas 7 refuses to install or uninstall without root, and Homebrew's bundler shells
# out to a plain `mas install` — so every App Store entry in the Brewfile fails under
# `brew bundle`. Handle them here, under sudo, one at a time so a single unavailable
# app doesn't take the rest down with it.
function _brew_mas {
  local action="$1" id
  shift
  for id in "$@"; do
    echo -e "\033[1mmas:\033[0m ${action}ing $(_brew_label mas "$id")..."
    sudo mas "$action" "$id" || echo -e "\033[0;31mmas: ${action} failed for $(_brew_label mas "$id")\033[0m" >&2
  done
}

function brew-sync {
  local green='\033[0;32m' yellow='\033[0;33m' cyan='\033[0;36m' red='\033[0;31m'
  local bold='\033[1m' dim='\033[2m' reset='\033[0m'

  _brew_diff || return 1

  local has_new=false has_missing=false has_untrusted=false
  local type
  for type in tap brew cask mas; do
    [ -s "$BREW_DIFF_DIR/new_${type}" ] && has_new=true
    [ -s "$BREW_DIFF_DIR/missing_${type}" ] && has_missing=true
  done
  for type in brew cask; do
    [ -s "$BREW_DIFF_DIR/untrusted_${type}" ] && has_untrusted=true
  done

  # Show diff
  echo ""
  if [ "$has_missing" = true ]; then
    echo -e "${bold}=== MISSING packages (in Brewfile but not installed) ===${reset}"
    echo ""
    for type in tap brew cask mas; do
      if [ -s "$BREW_DIFF_DIR/missing_${type}" ]; then
        echo -e "  ${bold}${type}:${reset}"
        while IFS= read -r pkg; do
          echo -e "    ${yellow}- $(_brew_label "$type" "$pkg")${reset}"
        done <"$BREW_DIFF_DIR/missing_${type}"
        echo ""
      fi
    done
  fi

  if [ "$has_untrusted" = true ]; then
    echo -e "${bold}=== UNTRUSTED taps (installed, but Homebrew won't load them) ===${reset}"
    echo ""
    for type in brew cask; do
      if [ -s "$BREW_DIFF_DIR/untrusted_${type}" ]; then
        echo -e "  ${bold}${type}:${reset}"
        while IFS= read -r pkg; do
          echo -e "    ${red}! ${pkg}${reset}"
        done <"$BREW_DIFF_DIR/untrusted_${type}"
        echo ""
      fi
    done
    echo -e "${dim}These are already installed. Homebrew refuses to load them from"
    echo -e "their taps, so 'brew bundle dump' omits them and they look missing."
    echo -e "Installing will not help. Trust the taps instead:${reset}"
    for type in brew cask; do
      [ -s "$BREW_DIFF_DIR/untrusted_${type}" ] || continue
      while IFS= read -r pkg; do
        case "$pkg" in
          */*/*) echo -e "  ${cyan}brew trust ${pkg%/*}${reset}" ;;
        esac
      done <"$BREW_DIFF_DIR/untrusted_${type}"
    done | sort -u
    echo ""
  fi

  if [ "$has_new" = true ]; then
    echo -e "${bold}=== EXTRA packages (installed but not in Brewfile) ===${reset}"
    echo ""
    for type in tap brew cask mas; do
      if [ -s "$BREW_DIFF_DIR/new_${type}" ]; then
        echo -e "  ${bold}${type}:${reset}"
        while IFS= read -r pkg; do
          echo -e "    ${green}+ $(_brew_label "$type" "$pkg")${reset}"
        done <"$BREW_DIFF_DIR/new_${type}"
        echo ""
      fi
    done
  fi

  if [ "$has_new" = false ] && [ "$has_missing" = false ]; then
    [ "$has_untrusted" = false ] && echo -e "${green}Everything is in sync.${reset}"
    rm -rf "$BREW_DIFF_DIR"
    return 0
  fi

  # Action menu
  echo -e "${cyan}Brewfile: ${BREW_DIFF_BREWFILE}${reset}"
  echo ""
  echo -e "${bold}Actions:${reset}"
  [ "$has_missing" = true ] && echo -e "  ${yellow}i${reset} = install missing    ${yellow}I${reset} = select which to install"
  [ "$has_new" = true ] && echo -e "  ${red}c${reset} = cleanup extras     ${red}C${reset} = select which to remove"
  echo -e "  ${dim}q${reset} = quit"
  echo ""
  printf "Action: "
  read -r ans

  case "$ans" in
    i)
      echo ""
      if [ -s "$BREW_DIFF_DIR/missing_mas" ]; then
        local mas_ids=()
        while IFS= read -r pkg; do mas_ids+=("$pkg"); done <"$BREW_DIFF_DIR/missing_mas"
        _brew_mas install "${mas_ids[@]}"
        echo ""
      fi
      brew bundle --global --no-upgrade
      ;;
    I)
      echo ""
      for type in tap brew cask mas; do
        [ -s "$BREW_DIFF_DIR/missing_${type}" ] || continue
        while IFS= read -r pkg <&3; do
          printf "Install %s %s? [y/N] " "$type" "$(_brew_label "$type" "$pkg")"
          read -r confirm
          if [[ "$confirm" == [yY] ]]; then
            case "$type" in
              tap) brew tap "$pkg" ;;
              brew) brew install "$pkg" ;;
              cask) brew install --cask "$pkg" ;;
              mas) _brew_mas install "$pkg" ;;
            esac
          fi
        done 3<"$BREW_DIFF_DIR/missing_${type}"
      done
      ;;
    c)
      echo ""
      brew bundle cleanup --global --force
      ;;
    C)
      echo ""
      for type in tap brew cask mas; do
        [ -s "$BREW_DIFF_DIR/new_${type}" ] || continue
        while IFS= read -r pkg <&3; do
          printf "Remove %s %s? [y/N] " "$type" "$(_brew_label "$type" "$pkg")"
          read -r confirm
          if [[ "$confirm" == [yY] ]]; then
            case "$type" in
              tap) brew untap "$pkg" ;;
              brew) brew uninstall "$pkg" ;;
              cask) brew uninstall --cask "$pkg" ;;
              mas) _brew_mas uninstall "$pkg" ;;
            esac
          fi
        done 3<"$BREW_DIFF_DIR/new_${type}"
      done
      ;;
    *)
      ;;
  esac
  rm -rf "$BREW_DIFF_DIR"
}
