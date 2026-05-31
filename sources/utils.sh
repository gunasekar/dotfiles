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
#   new_{tap,brew,cask,mas}, missing_{tap,brew,cask,mas}
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

    # Extract type\tname pairs, filtering OS-conditional blocks in curated Brewfile
    _brew_extract() {
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

    echo -e "\033[1mbrew:\033[0m Comparing against curated Brewfile..."

    _brew_extract "$BREW_DIFF_DIR/dump" none > "$BREW_DIFF_DIR/dump_entries"
    _brew_extract "$BREW_DIFF_BREWFILE" os > "$BREW_DIFF_DIR/curated_entries"
    unset -f _brew_extract

    local type
    for type in tap brew cask mas; do
        grep "^${type}	" "$BREW_DIFF_DIR/dump_entries" | cut -f2 > "$BREW_DIFF_DIR/dump_${type}" 2>/dev/null || true
        grep "^${type}	" "$BREW_DIFF_DIR/curated_entries" | cut -f2 > "$BREW_DIFF_DIR/curated_${type}" 2>/dev/null || true
        comm -23 "$BREW_DIFF_DIR/dump_${type}" "$BREW_DIFF_DIR/curated_${type}" > "$BREW_DIFF_DIR/new_${type}" 2>/dev/null || true
        comm -13 "$BREW_DIFF_DIR/dump_${type}" "$BREW_DIFF_DIR/curated_${type}" > "$BREW_DIFF_DIR/missing_${type}" 2>/dev/null || true
    done
}

function brew-sync {
    local green='\033[0;32m' yellow='\033[0;33m' cyan='\033[0;36m' red='\033[0;31m'
    local bold='\033[1m' dim='\033[2m' reset='\033[0m'

    _brew_diff || return 1

    local has_new=false has_missing=false
    local type
    for type in tap brew cask mas; do
        [ -s "$BREW_DIFF_DIR/new_${type}" ] && has_new=true
        [ -s "$BREW_DIFF_DIR/missing_${type}" ] && has_missing=true
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
                    echo -e "    ${yellow}- ${pkg}${reset}"
                done < "$BREW_DIFF_DIR/missing_${type}"
                echo ""
            fi
        done
    fi

    if [ "$has_new" = true ]; then
        echo -e "${bold}=== EXTRA packages (installed but not in Brewfile) ===${reset}"
        echo ""
        for type in tap brew cask mas; do
            if [ -s "$BREW_DIFF_DIR/new_${type}" ]; then
                echo -e "  ${bold}${type}:${reset}"
                while IFS= read -r pkg; do
                    echo -e "    ${green}+ ${pkg}${reset}"
                done < "$BREW_DIFF_DIR/new_${type}"
                echo ""
            fi
        done
    fi

    if [ "$has_new" = false ] && [ "$has_missing" = false ]; then
        echo -e "${green}Everything is in sync.${reset}"
        rm -rf "$BREW_DIFF_DIR"
        return 0
    fi

    # Action menu
    echo -e "${cyan}Brewfile: ${BREW_DIFF_BREWFILE}${reset}"
    echo ""
    echo -e "${bold}Actions:${reset}"
    [ "$has_missing" = true ] && echo -e "  ${yellow}i${reset} = install missing    ${yellow}I${reset} = select which to install"
    [ "$has_new" = true ]     && echo -e "  ${red}c${reset} = cleanup extras     ${red}C${reset} = select which to remove"
    echo -e "  ${dim}q${reset} = quit"
    echo ""
    printf "Action: "
    read -r ans

    case "$ans" in
        i)
            echo ""
            brew bundle --global --no-upgrade
            ;;
        I)
            echo ""
            for type in tap brew cask mas; do
                [ -s "$BREW_DIFF_DIR/missing_${type}" ] || continue
                while IFS= read -r pkg; do
                    printf "Install %s %s? [y/N] " "$type" "$pkg"
                    read -r confirm
                    if [[ "$confirm" == [yY] ]]; then
                        case "$type" in
                            tap)  brew tap "$pkg" ;;
                            brew) brew install "$pkg" ;;
                            cask) brew install --cask "$pkg" ;;
                            mas)  mas install "$pkg" ;;
                        esac
                    fi
                done < "$BREW_DIFF_DIR/missing_${type}"
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
                while IFS= read -r pkg; do
                    printf "Remove %s %s? [y/N] " "$type" "$pkg"
                    read -r confirm
                    if [[ "$confirm" == [yY] ]]; then
                        case "$type" in
                            tap)  brew untap "$pkg" ;;
                            brew) brew uninstall "$pkg" ;;
                            cask) brew uninstall --cask "$pkg" ;;
                            mas)  mas uninstall "$pkg" ;;
                        esac
                    fi
                done < "$BREW_DIFF_DIR/new_${type}"
            done
            ;;
        *)
            ;;
    esac
    rm -rf "$BREW_DIFF_DIR"
}
