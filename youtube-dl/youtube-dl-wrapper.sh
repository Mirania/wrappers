#!/bin/bash

if [ "$YOUTUBEDL" == "" ]; then
    echo "Please install youtube-dl and set the 'YOUTUBEDL' environment variable to the path to youtube-dl.exe."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 2
fi

if [ "$OUTDIR" == "" ]; then
    echo "Please set the 'OUTDIR' environment variable to the path where downloaded files should appear."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 2
fi

##### helper global vars #####
red=$(tput setf 4) # Red
green=$(tput setf 2) # Green
yellow=$(tput setf 6) # Yellow
blue=$(tput setf 1) # Blue
purple=$(tput setf 5) # Purple
cyan=$(tput setf 3) # Cyan
white=$(tput setf 7) # White

##### helper functions #####

fn_is_invalid_input() {
    if [ "$1" != "$(echo "$1" | sed 's/\$//g')" ]; then
        echo "${red}Error:${white} input must not contain the ${cyan}\$${white} symbol."
        true
    elif [ "$1" != "$(echo "$1" | sed -r "s/(.)+'(.)+//")" ]; then
        echo "${red}Error:${white} input can be 'quoted', but it must not contain the ${cyan}'${white} symbol somewhere in the middle."
        true
    else
        false
    fi
}

fn_ask_for_input() {
    local input
    inputerrorflag=1

    while [ "$inputerrorflag" -eq 1 ]; do
        read -p "➤ ${green}" input
        echo "${white}"
        if ! fn_is_invalid_input "$input"; then
            inputerrorflag=0
        fi
    done

    eval "$1="$input""
}

echo "-----------------------------------"
echo "|       youtube-dlp wrapper       |"
echo "-----------------------------------"
echo

fn_video() {
    local extension

    echo "Type the target extension (example: ${cyan}mov${white}, ${cyan}mp4${white}, ${cyan}mpeg${white})."
    echo "Leave empty to use the default value."
    fn_ask_for_input extension

    cd "$OUTDIR"

    if [ "$extension" != "" ] && [ "$1" != "" ]; then
        "$YOUTUBEDL" "$1" --recode-video "$extension" "$url"
    elif [ "$extension" != "" ]; then
        "$YOUTUBEDL" --recode-video "$extension" "$url"
    elif [ "$1" != "" ]; then
        "$YOUTUBEDL" "$1" "$url"
    else
        "$YOUTUBEDL" "$url"
    fi
}

fn_video_m3u_playlist() {
    cd "$OUTDIR"

    "$YOUTUBEDL" -o video.mp4 --merge-output-format mp4 "$url"
}

fn_audio() {
    local quality

    echo "Please input an ${green}audio quality${white} value. Should be between ${cyan}0${white} (highest) and ${cyan}9${white} (lowest)".
    echo "Leave empty to use the default value."
    fn_ask_for_input quality

    cd "$OUTDIR"

    if [ "$quality" != "" ]; then
        "$YOUTUBEDL" -x --audio-format mp3 --audio-quality "$quality" "$url"
    else
        "$YOUTUBEDL" -x --audio-format mp3 "$url"
    fi
}

fn_menu() {
    local option

    errorflag=0
    fn_ask_for_input option

    case $option in
        1) fn_video ;;
        2) fn_video "--embed-subs" ;;
        3) fn_video "--write-subs" ;;
        4) fn_video_m3u_playlist ;;
        5) fn_audio ;;
        *)
            echo "Unknown option ${red}'$option'${white}, please retry."
            errorflag=1
            ;;
    esac
}

echo "Please paste the ${green}URL${white} of the video/m3u/m3u8. Should start with ${green}https://${white}."
echo "To get a m3u/m3u8 URL, you may need to check the network tab in the browser and find the GET request of the playlist."
#do-while loop
fn_ask_for_input url
while [ "$url" == "" ]; do
    fn_ask_for_input url
done

echo "${cyan}Type to select an option:${white}"
echo
echo "1) Download video"
echo "2) Download video with embedded subs"
echo "3) Download video and create a subtitle file (.vtt)"
echo "4) Download video from a m3u/m3u8 playlist"
echo "5) Download audio"

#do-while loop
fn_menu
while [ "$errorflag" -eq 1 ]; do
    fn_menu
done

echo
read -p "Press any key to close..." -s -n 1
exit 0