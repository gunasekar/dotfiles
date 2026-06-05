#!/usr/bin/env bash

# <swiftbar.title>Market Mood Index</swiftbar.title>
# <swiftbar.version>v0.3</swiftbar.version>
# <swiftbar.author>Gunasekaran Namachivayam</swiftbar.author>
# <swiftbar.author.github>gunasekar</swiftbar.author.github>
# <swiftbar.desc>This plugin will show the market mood index</swiftbar.desc>
# <swiftbar.dependencies>shell,curl,jq</swiftbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:${PATH}"

CACHE_FILE="${SWIFTBAR_PLUGIN_DATA_PATH:-/tmp}/mmi_cache"

SENTIMENT_LABELS=("Extreme Fear" "Fear" "Greed" "Extreme Greed")
SENTIMENT_COLORS=("#ef4444" "#f97316" "#eab308" "#22c55e")
SENTIMENT_ICONS=("exclamationmark.triangle.fill" "arrow.down.circle.fill" "arrow.up.circle.fill" "flame.fill")

value=$(curl -s --max-time 10 --connect-timeout 5 "https://api.tickertape.in/mmi/now" 2>/dev/null | jq -r '.data.currentValue' 2>/dev/null)

if [[ -z "${value}" ]] || [[ "${value}" == "null" ]]; then
  if [[ -f "${CACHE_FILE}" ]]; then
    value=$(cat "${CACHE_FILE}")
    echo " | sfimage=questionmark.circle.fill color=#888888"
    echo '---'
    echo "Stale — $(printf "%.2f" "${value}") | sfimage=questionmark.circle.fill color=#888888"
  else
    echo " | sfimage=questionmark.circle.fill color=#888888"
    echo '---'
    echo "No data — check network | color=#888888"
  fi
  exit 0
fi

echo "${value}" > "${CACHE_FILE}"

int_val=${value%.*}
segment=$(( int_val / 25 ))
(( segment > 3 )) && segment=3

label="${SENTIMENT_LABELS[$segment]}"
color="${SENTIMENT_COLORS[$segment]}"
icon="${SENTIMENT_ICONS[$segment]}"

echo " | sfimage=${icon} color=${color}"
echo '---'
echo "${label} — $(printf "%.2f" "${value}") | sfimage=${icon} color=${color}"
echo '---'
echo "Refresh | refresh=true sfimage=arrow.clockwise"
