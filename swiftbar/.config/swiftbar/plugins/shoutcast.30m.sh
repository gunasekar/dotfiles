#!/bin/bash
# <swiftbar.title>Shoutcast</swiftbar.title>
# <swiftbar.version>v1.0</swiftbar.version>
# <swiftbar.desc>Browse and play SHOUTcast radio stations</swiftbar.desc>
# <swiftbar.dependencies>curl,jq,mpv</swiftbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

# Edit the default search and station limit here.
DEFAULT_SEARCH_QUERY="tamil"
STATION_LIMIT=15

case "$(uname -m)" in
  arm64) export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" ;;
  *) export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH" ;;
esac

directory=https://directory.shoutcast.com
script=${SWIFTBAR_PLUGIN_PATH:-$0}
[[ $script == /* ]] || script="$PWD/$script"
umask 077
state_dir="${SWIFTBAR_PLUGIN_DATA_PATH:-$HOME/Library/Application Support/Shoutcast SwiftBar}"
mkdir -p "$state_dir" && cd "$state_dir" || exit 1
# A relative socket path avoids macOS's Unix socket path length limit.
socket=player.sock
SEARCH_QUERY=$DEFAULT_SEARCH_QUERY
if [[ -s search-query ]]; then
  IFS= read -r SEARCH_QUERY <search-query
fi

post() {
  curl -fsS --connect-timeout 3 --max-time 8 --data-urlencode "$2" "$directory/$1"
}

ipc() {
  printf '%s\n' "$1" | /usr/bin/nc -w 1 -U "$socket" 2>/dev/null
}

reply() {
  ipc "$1" | jq -ne 'first(inputs | select(has("error"))) | select(.error == "success")'
}

player_running() {
  [[ -S $socket ]] && reply '{"command":["get_property","idle-active"]}' >/dev/null
}

player_playing() {
  reply '{"command":["get_property","core-idle"]}' | jq -e '.data == false' >/dev/null
}

play() {
  local id=$1 url command player_pid=''
  [[ $id =~ ^[0-9]+$ ]] || return 1
  url=$(post Player/GetStreamUrl "station=$id" |
    jq -er 'strings | sub("\\?icy=http$"; "") | select(test("^https?://[^[:space:][:cntrl:]]+$"))') || return 1

  if ! player_running; then
    nohup mpv --no-video --idle=once --input-media-keys=yes --input-ipc-server="$socket" \
      </dev/null >player.log 2>&1 &
    player_pid=$!
    for _ in {1..20}; do
      player_running && break
      kill -0 "$player_pid" 2>/dev/null || return 1
      sleep 0.1
    done
  fi

  command=$(jq -cn --arg url "$url" '{command:["loadfile",$url,"replace"]}')
  if ! reply "$command" >/dev/null; then
    [[ -z $player_pid ]] || kill "$player_pid" 2>/dev/null
    return 1
  fi
  reply '{"command":["set_property","pause",false]}' >/dev/null
  command=$(jq -cn --arg id "$id" '{command:["set_property","user-data/shoutcast/station",$id]}')
  reply "$command" >/dev/null || return 1

  # SwiftBar refreshes when the action exits. Give a buffering stream time to start.
  for _ in {1..10}; do
    player_playing && break
    player_running || break
    sleep 0.2
  done
  return 0
}

stop() {
  player_running || return 0
  ipc '{"command":["quit"]}' >/dev/null
  # Keep the action lock until mpv closes the socket.
  for _ in {1..20}; do
    player_running || return 0
    sleep 0.1
  done
  return 1
}

for dependency in jq mpv; do
  if ! command -v "$dependency" >/dev/null; then
    printf '%s\n' ' | sfimage=radio' '---'
    printf '%s is required\n' "$dependency"
    exit 0
  fi
done

case "${1:-}" in
  search)
    query=$(
      /usr/bin/osascript - "$SEARCH_QUERY" <<'APPLESCRIPT'
on run argv
  tell current application to activate
  display dialog "Search by language, city, genre, or station name. Leave blank to restore the default." default answer (item 1 of argv) with title "Shoutcast" buttons {"Cancel", "Search"} default button "Search" cancel button "Cancel"
  return text returned of result
end run
APPLESCRIPT
    ) || exit 0
    query=$(printf '%s' "$query" | tr '\r\n' '  ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -z $query ]]; then
      rm -f search-query
    else
      temp=$(mktemp query.XXXXXX) || exit 1
      printf '%s\n' "$query" >"$temp" && mv -f "$temp" search-query || exit 1
    fi
    exit 0
    ;;
  play | stop | reload)
    if [[ $1 == reload ]]; then
      rm -f list.fresh
      exit
    fi
    for _ in {1..120}; do
      /usr/bin/shlock -f action.lock -p "$$" && break
      sleep 0.1
    done
    [[ $(cat action.lock 2>/dev/null) == "$$" ]] || exit 1
    trap 'rm -f action.lock' EXIT
    rm -f action-error
    if [[ $1 == stop ]]; then
      stop || printf '%s\n' 'Could not stop the radio player' >action-error
    elif ! play "${2:-}"; then
      printf '%s\n' 'Could not start the selected station' >action-error
      exit 1
    fi
    exit 0
    ;;
  "") ;;
  *) exit 1 ;;
esac

active=''
running=false
header=' | sfimage=radio'
if player_running; then
  running=true
  if player_playing; then
    header=' | sfimage=radio.fill'
    active=$(reply '{"command":["get_property","user-data/shoutcast/station"]}' | jq -r '.data')
  fi
fi
printf '%s\n' "$header" '---'

if [[ $running == true ]]; then
  printf "Stop Radio | bash='%s' param1=stop terminal=false refresh=true\n" "$script"
fi
if [[ -s action-error ]]; then
  cat action-error
fi
printf 'Stations matching “%s” | color=#777777\n' "${SEARCH_QUERY//|/¦}"

cached=$(jq -ec --arg query "$SEARCH_QUERY" 'objects | select(.query == $query) | .stations | arrays' stations.json 2>/dev/null)
now=$(date +%s)
last_fetch=$(stat -f %m list.fresh 2>/dev/null || echo 0)
if [[ -z $cached ]] || ((now - last_fetch >= 1800)); then
  if stations=$(post Search/UpdateSearch "query=$SEARCH_QUERY" |
    jq -ec 'arrays | map(objects | select((.ID | tostring) | test("^[0-9]+$")))'); then
    cached=$stations
    if temp=$(mktemp stations.XXXXXX); then
      jq --arg query "$SEARCH_QUERY" '{query:$query, stations:.}' <<<"$stations" >"$temp" &&
        mv -f "$temp" stations.json && touch list.fresh
      rm -f "$temp"
    fi
  elif [[ -n $cached ]]; then
    printf 'SHOUTcast unavailable · cached %s\n' "$(stat -f %Sm -t '%b %d %H:%M' stations.json)"
  fi
fi

if [[ -z $cached ]]; then
  echo 'Could not fetch stations'
else
  jq -r --argjson limit "$STATION_LIMIT" --arg script "$script" --arg active "$active" '
    def menu_text: tostring | gsub("[[:cntrl:]]"; " ") | gsub("[|]"; "¦");
    map(objects | select((.ID | tostring) | test("^[0-9]+$")) |
      select((try (.Bitrate | tonumber) catch 0) > 0)) | .[:$limit] |
    if length == 0 then "No matching stations" else
    .[] |
    (if (.ID | tostring) == $active then "♪ " else "• " end) +
    "\(.Name | menu_text) · \(.Bitrate | menu_text) kbps · \(.Listeners | menu_text) listeners | bash=\u0027\($script)\u0027 param1=play param2=\(.ID) terminal=false refresh=true size=12" +
    (if (.ID | tostring) == $active then " color=#A3D948" else "" end)
    end
  ' <<<"$cached"
fi
printf '%s\n' '---'
printf "Search Stations… | bash='%s' param1=search terminal=false refresh=true\n" "$script"
printf "Refresh Stations | bash='%s' param1=reload terminal=false refresh=true\n" "$script"
