#!/usr/bin/env bash

# Display UTC in the menubar, and one or more additional zones in the drop down.
# Optimized for 1-minute refresh to keep menubar time accurate.
#
# <xbar.title>World Clock</xbar.title>
# <xbar.version>v1.2</xbar.version>
# <xbar.author>Adam Snodgrass</xbar.author>
# <xbar.author.github>asnodgrass</xbar.author.github>
# <xbar.dependencies>shell,date</xbar.dependencies>
# <xbar.desc>Display current UTC time in the menu bar, with various timezones in the drop-down menu</xbar.desc>
# <xbar.image>https://cloud.githubusercontent.com/assets/6187908/12207887/464ff8b2-b617-11e5-9d61-787eed228552.png</xbar.image>
# <xbar.var>string(VAR_ZONES="Australia/Sydney Asia/Singapore Asia/Kolkata Asia/Dubai Europe/Amsterdam America/New_York America/Los_Angeles"): Space delimited set of timezones</xbar.var>

ZONES=${VAR_ZONES}
date -u +'%H:%M UTC | refresh=true'
echo '---'
echo "$(date -u +'%H:%M:%S') UTC (click to refresh) | refresh=true"
for zone in ${ZONES}; do
  echo "$(TZ=${zone} date +'%H:%M:%S %z') ${zone} | refresh=true"
done
