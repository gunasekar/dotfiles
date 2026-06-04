#!/usr/bin/env bash

# Display UTC in the menubar, and one or more additional zones in the drop down.
# Optimized for 1-minute refresh to keep menubar time accurate.
#
# <swiftbar.title>World Clock</swiftbar.title>
# <swiftbar.version>v1.3</swiftbar.version>
# <swiftbar.author>Adam Snodgrass</swiftbar.author>
# <swiftbar.author.github>asnodgrass</swiftbar.author.github>
# <swiftbar.dependencies>shell,date</swiftbar.dependencies>
# <swiftbar.desc>Display current UTC time in the menu bar, with various timezones in the drop-down menu</swiftbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:${PATH}"

ZONES="Australia/Sydney Asia/Singapore Asia/Kolkata Asia/Dubai Europe/Amsterdam America/New_York America/Los_Angeles"
date -u +'%H:%M UTC'
echo '---'
echo "$(date -u +'%H:%M:%S') UTC (click to refresh) | refresh=true"
for zone in ${ZONES}; do
  echo "$(TZ=${zone} date +'%H:%M:%S %z') ${zone} | refresh=true"
done
