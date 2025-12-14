#!/usr/bin/env bash

# <xbar.title>Market Mood Index</xbar.title>
# <xbar.version>v0.2</xbar.version>
# <xbar.author>Gunasekaran Namachivayam</xbar.author>
# <xbar.author.github>gunasekar</xbar.author.github>
# <xbar.desc>This plugin will show the market mood index</xbar.desc>
# <xbar.dependencies>shell,curl,jq</xbar.dependencies>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:${PATH}"

# Cache file for last known value
CACHE_FILE="/tmp/mmi_cache"

# Market sentiment emoji map
SENTIMENTS=("🔴" "🟠" "🟡" "🟢")

# Fetch and process sentiment value with timeout
value=$(curl -s --max-time 10 --connect-timeout 5 "https://api.tickertape.in/mmi/now" 2>/dev/null | jq -r '.data.currentValue' 2>/dev/null)

# Check if we got a valid response
if [[ -z "${value}" ]] || [[ "${value}" == "null" ]]; then
  # Try to use cached value
  if [[ -f "${CACHE_FILE}" ]]; then
    value=$(cat "${CACHE_FILE}")
    echo "❓$(printf "%.2f" "${value}") | refresh=true"
    echo "---"
    echo "Using cached value (API unavailable)"
  else
    echo "❓ MMI | refresh=true"
    echo "---"
    echo "Unable to fetch Market Mood Index"
    echo "Check network connection"
  fi
  exit 0
fi

# Cache the successful value
echo "${value}" > "${CACHE_FILE}"

# Calculate sentiment segment and format value
segment=$((${value%.*} / 25))
formatted_value=$(printf "%.2f" "${value}")

# Print result
echo "${SENTIMENTS[${segment}]}${formatted_value} | refresh=true"

# Previous Endpoint - https://api.smallcase.com/market/indices/marketMoodIndex
