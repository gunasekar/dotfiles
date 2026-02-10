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

function brew-backup {
    brew bundle dump --no-vscode --force --global
}

function brew-check {
    if ! command -v brew &>/dev/null; then
        echo "Error: brew is not installed" >&2
        return 1
    fi

    local brewfile="${HOMEBREW_BUNDLE_FILE:-$HOME/.Brewfile}"
    if [ ! -f "$brewfile" ]; then
        echo "Error: Brewfile not found at $brewfile" >&2
        return 1
    fi

    # Colors
    local green='\033[0;32m' yellow='\033[0;33m' cyan='\033[0;36m'
    local bold='\033[1m' dim='\033[2m' reset='\033[0m'

    # Detect current OS
    local current_os
    if [[ "$OSTYPE" == darwin* ]]; then
        current_os="mac"
    else
        current_os="linux"
    fi

    # Extract type\tname pairs from a Brewfile, filtering out entries
    # inside OS-conditional blocks that don't match the current host.
    # Usage: _brew_check_extract <file> [filter]
    #   filter=os   - skip entries in incompatible OS blocks (for curated Brewfile)
    #   filter=none - extract everything (for brew dump output, which has no conditionals)
    _brew_check_extract() {
        local file="$1" filter="${2:-none}"
        awk -v os="$current_os" -v filter="$filter" '
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
                name = a[2]
                gsub(/[",]/, "", name)
                print type "\t" name
            }
        ' "$file" | sort -u
    }

    # Dump current state to temp file
    local tmpdir
    tmpdir=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '$tmpdir'" EXIT INT TERM

    echo -e "${bold}brew-check:${reset} Dumping current brew state..."
    if ! brew bundle dump --no-vscode --file="$tmpdir/dump" 2>/dev/null; then
        echo "Error: brew bundle dump failed" >&2
        return 1
    fi

    echo -e "${bold}brew-check:${reset} Comparing against curated Brewfile..."
    echo ""

    # Extract entries from both files (filter OS blocks in curated Brewfile)
    _brew_check_extract "$tmpdir/dump" none > "$tmpdir/dump_entries"
    _brew_check_extract "$brewfile" os > "$tmpdir/curated_entries"

    local has_new=false has_missing=false

    # Show NEW packages (installed but not in Brewfile)
    echo -e "${bold}=== NEW packages (installed but not in Brewfile) ===${reset}"
    echo ""
    for type in tap brew cask mas; do
        grep "^${type}	" "$tmpdir/dump_entries" | cut -f2 > "$tmpdir/dump_${type}" 2>/dev/null || true
        grep "^${type}	" "$tmpdir/curated_entries" | cut -f2 > "$tmpdir/curated_${type}" 2>/dev/null || true
        local new
        new=$(comm -23 "$tmpdir/dump_${type}" "$tmpdir/curated_${type}" 2>/dev/null)
        echo -e "  ${bold}${type}:${reset}"
        if [ -n "$new" ]; then
            has_new=true
            while IFS= read -r pkg; do
                echo -e "    ${green}+ ${pkg}${reset}"
            done <<< "$new"
        else
            echo -e "    ${dim}(none)${reset}"
        fi
        echo ""
    done

    # Show MISSING packages (in Brewfile but not installed)
    echo -e "${bold}=== MISSING packages (in Brewfile but not installed) ===${reset}"
    echo ""
    for type in tap brew cask mas; do
        local missing
        missing=$(comm -13 "$tmpdir/dump_${type}" "$tmpdir/curated_${type}" 2>/dev/null)
        echo -e "  ${bold}${type}:${reset}"
        if [ -n "$missing" ]; then
            has_missing=true
            while IFS= read -r pkg; do
                echo -e "    ${yellow}- ${pkg}${reset}"
            done <<< "$missing"
        else
            echo -e "    ${dim}(none)${reset}"
        fi
        echo ""
    done

    # Summary
    if [ "$has_new" = false ] && [ "$has_missing" = false ]; then
        echo -e "${green}Everything is in sync.${reset}"
    fi
    echo -e "${cyan}Curated Brewfile: ${brewfile} (not modified)${reset}"
    if [ "$has_new" = true ]; then
        echo -e "${cyan}Tip: Manually add new packages to the appropriate section in your Brewfile.${reset}"
    fi
    unset -f _brew_check_extract
}

function brew-restore {
    brew bundle --global
}

function brew-cleanup {
    brew bundle cleanup --global --force
}
