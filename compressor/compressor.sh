#!/bin/bash


if [ "$FFMPEG" == "" ]; then
    echo "Please install FFMPEG and set the 'FFMPEG' environment variable to the path to ffmpeg.exe."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 2
fi

if [ "$MAGICK" == "" ]; then
    echo "Please install ImageMagick and set the 'MAGICK' environment variable to the path to magick.exe."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 3
fi

if [ "$1" == "" ]; then
    echo "${cyan}Usage:${white}"
    echo "- Drag a video or image file to this application."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 4
fi

##### helper global vars #####
red=$(tput setf 4) # Red
green=$(tput setf 2) # Green
yellow=$(tput setf 6) # Yellow
blue=$(tput setf 1) # Blue
purple=$(tput setf 5) # Purple
cyan=$(tput setf 3) # Cyan
white=$(tput setf 7) # White
#parse filename and filepath
file=$1
fullpath=$(echo "$file" | sed 's/\\/\//g')
IFS='/' read -ra pathsegments <<< "$fullpath"
filename=${pathsegments[-1]}
IFS="." read -ra filesegments <<< "$filename"
extension=${filesegments[-1]}
unset 'pathsegments[-1]'
#variables for outputting a file
outfilepath=$(IFS='/' ; echo "${pathsegments[*]}")
outfilename=$(echo "$filename" | sed "s/['|\"|$|@|#]//g")

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

fn_generate_name() {
    local dorandom
    local id
    local result

    #convert to boolean
    if [ "$1" == "y" ] || [ "$1" == "Y" ] || [ "$1" == "" ]; then dorandom=1; else dorandom=0; fi

    if [ "$dorandom" -eq 1 ]; then
        id=$((1 + $RANDOM % 150))
        result="$2/$5$id.$3"
    else
        result="$2/new $4"
    fi

    echo "$result"
}

fn_log_created_if_successful() {
    if [ "$?" -eq 0 ]; then
        echo
        echo "Created the file ${cyan}$1${white}"
    fi
}

if fn_is_invalid_input "$file"; then
    echo
    read -p "Press any key to close..." -s -n 1
    exit 1;
fi

echo "-------------------------"
echo "     compressor tool     "
echo "-------------------------"
echo 

fn_video() {
    local crf
    local obfuscate
    local sum
    local generated

    echo "Type a compression level. Should be between ${cyan}1${white} (low) and ${cyan}20${white} (high)."
    echo "Leave empty for the default value of ${cyan}8${white}."
    fn_ask_for_input crf

    #set default
    if [ "$crf" == "" ]; then crf=8; fi

    echo "Type ${cyan}y${white} or leave empty to generate a non-descriptive name for the file."
    echo "For example, ${green}video0.$extension${white}. Otherwise, type ${cyan}n${white}."
    fn_ask_for_input obfuscate

    generated=$(fn_generate_name "$obfuscate" "$outfilepath" "$extension" "$outfilename" "video")

    sum=$(($crf+19))
    "$FFMPEG" -i "$file" -vcodec libx264 -crf $sum "$generated"
    fn_log_created_if_successful "$generated"
}

fn_png() {
    local quality
    local outext
    local generated

    echo "Type a quality. Should be between ${cyan}1${white} (low) and ${cyan}100${white} (high)."
    echo "Leave empty for the default value of ${cyan}80${white}."
    fn_ask_for_input quality

    echo "Type ${cyan}y${white} or leave empty to keep the file as a ${cyan}png${white}."
    echo "Otherwise, type ${cyan}n${white} to convert to ${cyan}jpg${white}."
    fn_ask_for_input outext

    #set defaults
    if [ "$quality" == "" ]; then quality=80; fi
    if [ "$outext" == "y" ] || [ "$outext" == "Y" ] || [ "$outext" == "" ]; then outext="$extension"; else outext="jpg"; fi

    echo "Type ${cyan}y${white} or leave empty to generate a non-descriptive name for the file."
    echo "For example, ${green}image0.$outext${white}. Otherwise, type ${cyan}n${white}."
    fn_ask_for_input obfuscate

    generated=$(fn_generate_name "$obfuscate" "$outfilepath" "$outext" "$outfilename" "image")

    "$MAGICK" convert -quality $quality "$file" "$generated"
    fn_log_created_if_successful "$generated"
}

fn_jpg() {
    local quality
    local generated

    echo "Type a quality. Should be between ${cyan}1${white} (low) and ${cyan}100${white} (high)."
    echo "Leave empty for the default value of ${cyan}80${white}."
    fn_ask_for_input quality

    #set default
    if [ "$quality" == "" ]; then quality=80; fi

    echo "Type ${cyan}y${white} or leave empty to generate a non-descriptive name for the file."
    echo "For example, ${green}image0.$extension${white}. Otherwise, type ${cyan}n${white}."
    fn_ask_for_input obfuscate

    generated=$(fn_generate_name "$obfuscate" "$outfilepath" "$extension" "$outfilename" "image")

    "$MAGICK" "$file" -strip -interlace Plane -sampling-factor 4:2:0 -define jpeg:dct-method=float -quality $quality% "$generated"
    fn_log_created_if_successful "$generated"
}

fn_gif() {
    local compression
    local generated

    echo "Type a compression level. Should be between ${cyan}1${white} (low) and ${cyan}100${white} (high)."
    echo "Leave empty for the default value of ${cyan}5${white}."
    fn_ask_for_input compression

    #set default
    if [ "$compression" == "" ]; then compression=5; fi

    echo "Type ${cyan}y${white} or leave empty to generate a non-descriptive name for the file."
    echo "For example, ${green}image0.$extension${white}. Otherwise, type ${cyan}n${white}."
    fn_ask_for_input obfuscate

    generated=$(fn_generate_name "$obfuscate" "$outfilepath" "$extension" "$outfilename" "image")
    
    cp "$file" "$generated"
    "$MAGICK" mogrify -coalesce +dither -layers 'optimize' -fuzz $compression% "$generated"
    fn_log_created_if_successful "$generated"
}

fn_main() {
    if [ "$extension" == "mp4" ] || [ "$extension" == "mov" ] || [ "$extension" == "webm" ] ||
       [ "$extension" == "MP4" ] || [ "$extension" == "MOV" ] || [ "$extension" == "WEBM" ] ; then
        fn_video;
    elif [ "$extension" == "png" ] ||
         [ "$extension" == "PNG" ]; then
        fn_png;
    elif [ "$extension" == "jpg" ] || [ "$extension" == "jpeg" ] ||
         [ "$extension" == "JPG" ] || [ "$extension" == "JPEG" ]; then
        fn_jpg;
    elif [ "$extension" == "gif" ] ||
         [ "$extension" == "GIF" ]; then
        fn_gif;
    else
        echo "Unrecognised format '.$extension'"
        echo "Try converting it to a more common image/video format."
        echo
        read -p "Press any key to continue..." -s -n 1
    fi
}

#guess procedure and run
fn_main

echo
read -p "Press any key to close..." -s -n 1
exit 0
