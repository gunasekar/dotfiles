#!/bin/bash

##### constants
audioDir="$HOME/Downloads/media/audio"
videoDir="$HOME/Downloads/media/video"

alias shout-tamil="shoutcast tamil 15"

##### yt-dlp (modern youtube-dl fork)
function yt-dlp_video_and_audio_best_no_mkv_merge {
  video_type=$(yt-dlp -F "$@" | grep "video only" | awk '{print $2}' | tail -n 1)
  case $video_type in
    mp4)
      yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]' -o "$videoDir/%(title)s.%(ext)s" "$@";;
    webm)
      yt-dlp -f 'bestvideo[ext=webm]+bestaudio[ext=webm]' -o "$videoDir/%(title)s.%(ext)s" "$@";;
    *)
      echo "New best videoformat detected - $video_type, please check it out!";;
  esac
}

function dl-audio {
    if ! command -v yt-dlp &>/dev/null; then
        echo "yt-dlp not found. brewing..."
        brew install yt-dlp
    fi

    mkdir -p "$audioDir"
    for id in "$@"
    do
        yt-dlp -x --audio-format mp3 -o "$audioDir/%(title)s.%(ext)s" "$id"
    done
}

function dl-video {
    if ! command -v yt-dlp &>/dev/null; then
        echo "yt-dlp not found. brewing..."
        brew install yt-dlp
    fi

    mkdir -p "$videoDir"
    for id in "$@"
    do
        # More flexible format selection with fallbacks for YouTube's changing formats
        # Priority: mp4 with best quality, fallback to any best available
        yt-dlp \
            -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best' \
            --merge-output-format mp4 \
            -o "$videoDir/%(title)s.%(ext)s" \
            "$id"
    done
}


function play_sound {
    if command -v afplay &>/dev/null; then
        afplay "$(get-audio)"
    else
        i=5
        while [ $i -ge 0 ]; do
            echo -ne '\007'
            sleep 0.5
            ((i--))
        done
    fi
}

function get-audio {
    local pacdies=~/.pacdies.mp3
    if ! [ -f $pacdies ]; then
        wget "https://raw.githubusercontent.com/gunasekar/shell/master/pacdies.mp3" -O $pacdies
    fi

    echo $pacdies
}

function notify-on-completion-fg {
    if [[ $# -gt 0 ]]; then
        # Assume a PID has been passed
        while [[ $(ps -e | grep $1 | wc -l) != "0" ]]; do
            sleep 1
        done

        play_sound
    else
        play_sound
    fi
}

function notify-on-completion {
    notify-on-completion-fg "$@" &
}

function notify-after-fg {
    pacdies=$(get-audio)
    if [[ $# -gt 0 ]]; then
        # Assume number of seconds has been passed
        sleep $1

        play_sound
    else
        play_sound
    fi
}

function notify-after {
    notify-after-fg "$@" &
}

##### music related
function get-metadata {
    ffprobe "$@" 2>&1 | grep -A20 'Metadata:'
}

function shoutcast {
    if ! command -v curl &>/dev/null; then
        echo "curl not found. brewing..."
        brew install curl
    fi

    result=$(curl -s 'http://directory.shoutcast.com/Search/UpdateSearch' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'query='$1'')
    noOfStations=$(echo $result | jq ". | length")
    echo "$noOfStations found"
    if [ $# -ge 2 ]
    then
        noOfStations=$2
        echo $result | jq ".[0:$2]" | jq ".[] | \"\(.ID) --> \(.Name) ... Bitrate: \(.Bitrate) ... Listeners: \(.Listeners)\""
    else
        echo $result | jq ".[] | \"\(.ID) --> \(.Name) ... Bitrate: \(.Bitrate) ... Listeners: \(.Listeners)\""
    fi

    while true ;
    do
        printf "Select the stationID from the above stations: "
        read -r stationID
        if echo $result | grep -q "\"ID\":$stationID,"; then
            break
        else
            echo -e "\e[1;31mInvalid stationID!\e[0m"
        fi
    done

    stationName=$(echo $result | jq ".[] | if .ID == $stationID then \"\(.Name)\" else null end" | sed '/null/d' | sed -e 's/^"//' -e 's/"$//')
    echo "Playing station - $stationName"
    play-shoutcast-station $stationID
}

function play-shoutcast-station {
    if ! command -v curl &>/dev/null; then
        echo "curl not found. brewing..."
        brew install curl
    fi

    result=$(curl -s 'http://directory.shoutcast.com/Player/GetStreamUrl' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'station='$1'')
    # first sed removes the double quotes prefix and suffix. second sed removes '?icy=http'
    link=$(sed -e 's/^"//' -e 's/"$//' <<<"$result" | sed "s/?icy=http//")
    mpv $link
}

function download_m3u8 {
    echo "Enter m3u8 link:";read link;echo "Enter output filename:";read filename;ffmpeg -i "$link" -bsf:a aac_adtstoasc -vcodec copy -c copy -crf 50 $filename.mp4
}
