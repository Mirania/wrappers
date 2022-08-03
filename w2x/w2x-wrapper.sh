#!/bin/bash

if [ "$W2X" == "" ]; then
    echo "Please install waifu2x and set the 'W2X' environment variable to the path to waifu2x-converter-cpp.exe."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 2
fi

if [ "$W2XDIR" == "" ]; then
    echo "Please install waifu2x and set the 'W2XDIR' environment variable to the folder containing waifu2x-converter-cpp.exe."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 2
fi

if [ "$1" == "" ]; then
    echo "${cyan}Usage:${white}"
    echo "- Drag an image file to this application."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 3
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
unset 'pathsegments[-1]'
#split filename string by .
IFS="." read -ra filesegments <<< "$filename"
extension=${filesegments[-1]}
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

echo "-----------------------------------"
echo "|           w2x wrapper           |"
echo "-----------------------------------"
echo

fn_scale_jpg_webp() {
    local quality

    echo "Please input a ${green}quality${white} value. Should be between ${cyan}0${white} (lowest) and ${cyan}100${white} (highest)."
    fn_ask_for_input quality
    
    cd "$W2XDIR"
    "$W2X" -i "$file" -o "$outfilepath/new $outfilename" --scale-ratio $scale --noise-level $noise -q $quality
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_scale_png() {
    local compression

    echo "Please input a ${green}compression${white} value. Should be between ${cyan}0${white} (none) and ${cyan}9${white} (maximum)."
    fn_ask_for_input compression

    cd "$W2XDIR"
    "$W2X" -i "$file" -o "$outfilepath/new $outfilename" --scale-ratio $scale --noise-level $noise -c $compression
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_scale_other() {
    cd "$W2XDIR"
    "$W2X" -i "$file" -o "$outfilepath/new $outfilename" --scale-ratio $scale --noise-level $noise
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

echo "Please input a ${green}scale${white} value. Should be between ${cyan}1${white} and ${cyan}5${white}."
fn_ask_for_input scale

echo "Please input a ${green}noise reduction${white} value. Should be between ${cyan}0${white} and ${cyan}3${white}."
fn_ask_for_input noise

if [ "$extension" == "jpg" ] || [ "$extension" == "JPG" ] || 
   [ "$extension" == "jpeg" ] || [ "$extension" == "JPEG" ] ||
   [ "$extension" == "webp" ] || [ "$extension" == "WEBP" ]; then
    fn_scale_jpg_webp
elif [ "$extension" == "png" ] || [ "$extension" == "PNG" ]; then
    fn_scale_png
else
    fn_scale_other
fi

echo
read -p "Press any key to close..." -s -n 1
exit 0