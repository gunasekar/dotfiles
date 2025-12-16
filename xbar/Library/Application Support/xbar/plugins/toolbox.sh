#!/usr/bin/env bash

# <xbar.title>Toolbox</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Gunasekaran Namachivayam</xbar.author>
# <xbar.author.github>gunasekar</xbar.author.github>
# <xbar.desc>Handy menu bar app to serve as swiss-army knife for devs.</xbar.desc>
# <xbar.dependencies>shell,jq,sed,uuidgen,openssl,base64,zbarimg,date,curl</xbar.dependencies>

# Variables as preferences of the app:
#  <xbar.var>select(APP_ICON="🛠"): App icon to be shown in the menu app. [⚙️,🛠,DevToolBox]</xbar.var>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:${PATH}"
SCRIPT_PATH="$(realpath -q "$0")"

# Helper function to copy to clipboard without newline
function copyToClip() {
    tr -d '\n' | pbcopy
}

function createHeader() {
  echo "$1"
  echo "---"
  echo "$2"
}

function createMenu() {
  echo "$1"
}

function createAction() {
  echo "-- $1 | bash='${SCRIPT_PATH}' param1=$2 terminal=false refresh=true"
}

# ============================================
# TEXT OPERATIONS
# ============================================

# String functions
function toUpper() {
  pbpaste | tr '[:lower:]' '[:upper:]' | copyToClip
}

function toLower() {
  pbpaste | tr '[:upper:]' '[:lower:]' | copyToClip
}

# Sort functions
function sortLines() {
  pbpaste | sort | copyToClip
}

function sortLinesReverse() {
  pbpaste | sort -r | copyToClip
}

function sortLinesUnique() {
  pbpaste | sort -u | copyToClip
}

function sortLinesUniqueReverse() {
  pbpaste | sort -u -r | copyToClip
}

function sortLinesUniqueCaseInsensitive() {
  pbpaste | sort -u -f | copyToClip
}

function sortLinesUniqueCaseInsensitiveReverse() {
  pbpaste | sort -u -f -r | copyToClip
}

# ============================================
# ENCODING/DECODING
# ============================================

# Hex functions
function toHex() {
  pbpaste | xxd -p | copyToClip
}

function fromHex() {
  pbpaste | xxd -p -r | copyToClip
}

# URL functions
function encodeUrl() {
  pbpaste | jq -sRr @uri | copyToClip
}

function decodeUrl() {
    local url_encoded=$(pbpaste)
    local url_encoded="${url_encoded//+/ }"
    printf '%b' "${url_encoded//%/\\x}" | copyToClip
}

# Base64 functions
function encodeBase64() {
  pbpaste | base64 | copyToClip
}

function decodeBase64() {
  pbpaste | base64 -d | copyToClip
}

# ============================================
# CRYPTOGRAPHY
# ============================================

# UUID functions
function generateUUIDUpper() {
  uuidgen | tr '[:lower:]' '[:upper:]' | copyToClip
}

function generateUUIDLower() {
  uuidgen | tr '[:upper:]' '[:lower:]' | copyToClip
}

function generateRandHex8() {
  openssl rand -hex 50 | cut -c1-"8" | copyToClip
}

function generateRandHex16() {
  openssl rand -hex 50 | cut -c1-"16" | copyToClip
}

function generateRandHex32() {
  openssl rand -hex 50 | cut -c1-"32" | copyToClip
}

# Hash functions
function hashMD5() {
  pbpaste | openssl md5 | awk '{print $2}' | copyToClip
}

function hashSHA256() {
  pbpaste | openssl sha256 | awk '{print $2}' | copyToClip
}

# ============================================
# DATA FORMATS
# ============================================

# JSON functions
function prettifyJson() {
  pbpaste | jq . | pbcopy
}

function minifyJson() {
  pbpaste | jq -c . | copyToClip
}

function escapeJson() {
  pbpaste | jq @json | copyToClip
}

function unEscapeJson() {
  pbpaste | jq -r | copyToClip
}

# CSV functions
function json2csv() {
  pbpaste | jq --raw-output '(map(keys) | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' | pbcopy
}

function csv2json() {
  content=$(pbpaste)
    awk '
    BEGIN { FS = "," }
    NR == 1 {
        # Store header fields
        for (i=1; i<=NF; i++) {
            gsub(/^[ \t]+|[ \t]+$/, "", $i)  # Trim whitespace
            gsub(/^"|"$/, "", $i)  # Remove surrounding quotes
            header[i] = $i
        }
        printf "["
    }
    NR > 1 {
        # Print comma between objects
        if (NR > 2) printf ","
        printf "\n  {"

        # Process each field
        for (i=1; i<=NF; i++) {
            if (i > 1) printf ","
            gsub(/^[ \t]+|[ \t]+$/, "", $i)  # Trim whitespace
            gsub(/^"|"$/, "", $i)  # Remove surrounding quotes
            printf "\n    \"%s\": \"%s\"", header[i], $i
        }
        printf "\n  }"
    }
    END {
        if (NR > 1) printf "\n"
        printf "]\n"
    }' <<< "$content" | pbcopy
}

# ============================================
# DATE/TIME
# ============================================

# Date functions
function currentEpochSecond() {
    date +%s | copyToClip
}

function currentUTCISO8601() {
    date -u +%FT%TZ | copyToClip
}

function currentLocalISO8601() {
    date +%FT%TZ | copyToClip
}

function currentUTCTimestamp() {
    date -u +"%Y-%m-%d %H:%M:%S" | copyToClip
}

function currentLocalTimestamp() {
    date +"%Y-%m-%d %H:%M:%S" | copyToClip
}

function currentUTCDay() {
    date -u +"%Y-%m-%d" | copyToClip
}

function currentLocalDay() {
    date +"%Y-%m-%d" | copyToClip
}

function unixToLocalTimestamp() {
  date -r "$(pbpaste)" +%Y-%m-%dT%H:%M:%SZ | copyToClip
}

function unixToUtcTimestamp() {
  date -r "$(pbpaste)" -u +%Y-%m-%dT%H:%M:%SZ | copyToClip
}

# ============================================
# MEDIA/UTILITIES
# ============================================

# QR functions
function QRDecode() {
    tmp_file=$(mktemp)
    tmp_file_png="${tmp_file}.png"
    mv "$tmp_file" "$tmp_file_png"

    # Save clipboard image to temporary file
    pngpaste "$tmp_file_png"

    # Use zbarimg to decode QR code
    zbarimg --quiet --raw "$tmp_file_png" | copyToClip

    # Clean up temp file
    rm "$tmp_file_png"
}

[[ $# -ge 1 ]] && { $1 && exit $?; }

createHeader "${APP_ICON}" 'Toolbox'

# TEXT OPERATIONS
createMenu "String"
createAction "To Uppercase" toUpper
createAction "To Lowercase" toLower

createMenu "Sort"
createAction "Lines" sortLines
createAction "Lines Reverse" sortLinesReverse
createAction "Lines Unique" sortLinesUnique
createAction "Lines Unique Reverse" sortLinesUniqueReverse
createAction "Lines Unique Case Insensitive" sortLinesUniqueCaseInsensitive
createAction "Lines Unique Case Insensitive Reverse" sortLinesUniqueCaseInsensitiveReverse

# ENCODING/DECODING
createMenu "Hex"
createAction "To Hex" toHex
createAction "From Hex" fromHex

createMenu "URL"
createAction "Encode" encodeUrl
createAction "Decode" decodeUrl

createMenu "Base64"
createAction "Encode" encodeBase64
createAction "Decode" decodeBase64

# CRYPTOGRAPHY
createMenu "UUID"
createAction "Uppercase" generateUUIDUpper
createAction "Lowercase" generateUUIDLower
createAction "Random Hex 8" generateRandHex8
createAction "Random Hex 16" generateRandHex16
createAction "Random Hex 32" generateRandHex32

createMenu "Hash"
createAction "MD5" hashMD5
createAction "SHA256" hashSHA256

# DATA FORMATS
createMenu "JSON"
createAction "Format" prettifyJson
createAction "Minify" minifyJson
createAction "Escape" escapeJson
createAction "Unescape" unEscapeJson

createMenu "CSV"
createAction "JSON to CSV" json2csv
createAction "CSV to JSON" csv2json

# DATE/TIME
createMenu "Date"
createAction "Epoch Second" currentEpochSecond
createAction "UTC ISO8601" currentUTCISO8601
createAction "Local ISO8601" currentLocalISO8601
createAction "UTC YYYY-MM-DD hh:mm:ss" currentUTCTimestamp
createAction "Local YYYY-MM-DD hh:mm:ss" currentLocalTimestamp
createAction "UTC YYYY-MM-DD" currentUTCDay
createAction "Local YYYY-MM-DD" currentLocalDay
createAction "Unix to UTC ISO8601" unixToUtcTimestamp
createAction "Unix to Local ISO8601" unixToLocalTimestamp

# MEDIA/UTILITIES
createMenu "QR"
createAction "Decode" QRDecode
