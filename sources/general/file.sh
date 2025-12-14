#!/bin/bash

##### general
mkdir -p "$HOME/.binaries"
export PATH="$PATH:$HOME/.binaries"

function binplace {
    mkdir -p "$HOME/.binaries/"
    cp "$1" "$HOME/.binaries/"
    chmod 755 "$HOME/.binaries/"*
}

alias uts="date +%s"

##### custom
function merge-lines {
    if [[ $# != 2 ]]
    then
        echo "usage: merge-lines <file_path> <lines_to_merge>\nexample:\nmerge-lines payload.csv 5"
    else
        param='{line=line "," $0} NR%'$2'==0{print substr(line,2); line=""}'
        awk "$param" "$1" > "${1}_merged_${2}_lines.csv"
        [ $? -eq 0 ] && echo "merged to ${1}_merged_${2}_lines.csv" || echo "merge failed" >&2
    fi
}

function merge-csv {
    if [[ $# != 2 ]]
    then
        echo "usage: merge-csv <file1> <file2>\nexample:\nmerge-csv file1.csv file2.csv"
    else
        paste -d, "$1" "$2" > merged.csv
        [ $? -eq 0 ] && echo "merged to merged.csv" || echo "merge failed" >&2
    fi
}

function get-added-lines {
    diff -u "$1" "$2" | tail -n +3 | sed -n "s/^+\(.*\)/\1/p"
}

function get-removed-lines {
    diff -u "$1" "$2" | tail -n +3 | sed -n "s/^-\(.*\)/\1/p"
}

function compare-line-items {
    local USAGE="Usage: compare-line-items [-a|-r|-c] file1 file2
    -a: show only added lines
    -r: show only removed lines
    -c: show only common lines
    If no option is provided, shows all lines"

    local type="all"
    local OPTIND
    while getopts "arc" opt; do
        case $opt in
            a) type="added" ;;
            r) type="removed" ;;
            c) type="common" ;;
            ?) echo "$USAGE"; return 1 ;;
        esac
    done

    shift $((OPTIND-1))

    if [ "$#" -ne 2 ]; then
        echo "$USAGE"
        return 1
    fi

    if [ ! -f "$1" ] || [ ! -f "$2" ]; then
        echo "Error: Both arguments must be valid files"
        return 1
    fi

    # Create temporary files for sorted content
    local tmp1=$(mktemp)
    local tmp2=$(mktemp)

    # Sort files and store in temporary files
    sort "$1" > "$tmp1"
    sort "$2" > "$tmp2"

    # Perform diff based on requested type
    echo "=== Line Item Comparison between $1 and $2 ==="

    if [ "$type" = "removed" ] || [ "$type" = "all" ]; then
        echo "Lines only in $1 (removed):"
        comm -23 "$tmp1" "$tmp2"
    fi

    if [ "$type" = "added" ] || [ "$type" = "all" ]; then
        if [ "$type" = "all" ]; then
            echo -e "\nLines only in $2 (added):"
        else
            echo "Lines only in $2 (added):"
        fi
        comm -13 "$tmp1" "$tmp2"
    fi

    if [ "$type" = "common" ] || [ "$type" = "all" ]; then
        if [ "$type" = "all" ]; then
            echo -e "\nLines common to both files:"
        else
            echo "Lines common to both files:"
        fi
        comm -12 "$tmp1" "$tmp2"
    fi

    # Clean up temporary files
    rm "$tmp1" "$tmp2"
}

function ipinfo {
    curl ipinfo.io
}

function download_m3u8 {
    echo "Enter m3u8 link:";read link;echo "Enter output filename:";read filename;ffmpeg -i "$link" -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 "$filename.mp4"
}

function deduplicate {
    sort "$1" | uniq
}
