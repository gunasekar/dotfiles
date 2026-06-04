#!/usr/bin/env bash

# <swiftbar.title>Authenticator</swiftbar.title>
# <swiftbar.version>v0.4</swiftbar.version>
# <swiftbar.author>Gunasekaran Namachivayam, Oleksii Shurubura</swiftbar.author>
# <swiftbar.author.github>gunasekar</swiftbar.author.github>
# <swiftbar.desc>Generate TOTP tokens and copy them to clipboard</swiftbar.desc>
# <swiftbar.dependencies>shell,oathtool</swiftbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:${PATH}"

# Check if oathtool is installed
if ! command -v oathtool >/dev/null 2>&1; then
  echo "⚠️"
  echo '---'
  echo "oathtool not found"
  echo "Install with: brew install oath-toolkit"
  exit 1
fi

echo " | sfimage=key.fill"

if [[ -f "${HOME}/.totp_seeds" ]]; then
  source "${HOME}/.totp_seeds"
else
  echo '---'
  echo "\$HOME/.totp_seeds file not found"
  echo "Create file with seeds array"
  echo "---"
  exit 1
fi

function getTotp() {
  oathtool --totp -b "$1" 2>/dev/null
}

if [[ "$1" == "copy" ]]; then
  fresh_token=$(getTotp "$2")
  if [[ -n "${fresh_token}" ]]; then
    echo -n "${fresh_token}" | pbcopy
  fi
  exit 0
fi

echo '---'
echo "Clear Clipboard | bash='$0' param1=copy param2=' ' terminal=false refresh=true"
echo "---"

for seed in "${seeds[@]}"; do
  KEY="${seed%%:*}"
  VALUE="${seed##*:}"
  echo "${KEY} | bash='$0' param1=copy param2='${VALUE}' terminal=false refresh=true"
done
