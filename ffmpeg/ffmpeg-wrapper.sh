#!/bin/bash

if [ "$FFMPEG" == "" ]; then
    echo "Please install FFMPEG and set the 'FFMPEG' environment variable to the path to ffmpeg.exe."
    echo
    read -p "Press any key to close..." -s -n 1
    exit 2
fi

if [ "$1" == "" ]; then
    echo "${cyan}Usage:${white}"
    echo "- Drag a video or audio file to this application."
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

echo "----------------------------------"
echo "|         ffmpeg wrapper         |"
echo "----------------------------------"
echo 
echo "${cyan}Type to select an option:${white}"
echo
echo "1) Convert a file (example: mov -> mp4)"
echo "2) Compress a file (compression level of 8-10 is usually good)"
echo "3) Cut the start and/or end of a file (example: start at 5 seconds)"
echo "4) Combine an image and a sound file to create a video"
echo "5) Loop contents of a file (up to a declared filesize)"
echo "6) Replace the sound in a video"
echo "7) Crop a video"
echo "8) Concatenate files (this can be used to loop x amount of times)"
echo "9) Change video/audio playback speed"
echo "a) Resize a file (can be a gif!)"
echo "b) Change the volume of a file"
echo "c) Add text to a video"
echo "d) Reverse a video"
echo "e) Mix new audio into a video (does not replace existing sounds)"
echo "f) Mute a video (removes all sound)"

fn_convert() {
    local extension
    local filesegments

    echo "Type the target extension (example: ${cyan}mov${white}, ${cyan}mp4${white}, ${cyan}mp3${white}, ${cyan}mpeg${white})."
    fn_ask_for_input extension

    #split filename string by .
    IFS="." read -ra filesegments <<< "$filename"
    "$FFMPEG" -i "$file" "$outfilepath/new ${filesegments[0]}.$extension"
    fn_log_created_if_successful "$outfilepath/new ${filesegments[0]}.$extension"
}

fn_compress() {
    local crf
    local sum

    echo "Type a compression level. Should be between ${cyan}1${white} (low) and ${cyan}20${white} (high)."
    fn_ask_for_input crf

    sum=$(($crf+19))
    "$FFMPEG" -i "$file" -vcodec libx264 -crf $sum "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_cut() {
    local start
    local end

    echo "Type the start time (${cyan}mm:ss format${white}) - leave empty to skip"
    echo "Can also specify decimals, for example ${cyan}00:05.6${white}"
    fn_ask_for_input start
    echo "Type the stop time (${cyan}mm:ss format${white}) - leave empty to skip"
    echo "Can also specify decimals, for example ${cyan}00:07.2${white}"
    fn_ask_for_input end

    if [ "$start" != "" ] && [ "$end" != "" ]; then
        "$FFMPEG" -i "$file" -ss 00:"$start" -to 00:"$end" "$outfilepath/new $outfilename"
        fn_log_created_if_successful "$outfilepath/new $outfilename"
    elif [ "$start" != "" ]; then
        "$FFMPEG" -i "$file" -ss 00:"$start" "$outfilepath/new $outfilename"
        fn_log_created_if_successful "$outfilepath/new $outfilename"
    elif [ "$end" != "" ]; then
        "$FFMPEG" -i "$file" -to 00:"$end" "$outfilepath/new $outfilename"
        fn_log_created_if_successful "$outfilepath/new $outfilename"
    else
        echo "Nothing to do."
    fi
}

fn_img() {
    local imagefile
	local filesegments

    echo "Drag the image to this window."
    fn_ask_for_input imagefile
	
	#split filename string by .
    IFS="." read -ra filesegments <<< "$filename"

    "$FFMPEG" -loop 1 -i "$imagefile" -i "$file" -c:v libx264 -tune stillimage -c:a aac -b:a 192k \
            -pix_fmt yuv420p -shortest "$outfilepath/new ${filesegments[0]}.mp4"
    fn_log_created_if_successful "$outfilepath/new ${filesegments[0]}.mp4"
}

fn_loop() {
    local size

    echo "Loop until what filesize (in ${cyan}MB${white})?"
    fn_ask_for_input size

    "$FFMPEG" -stream_loop -1 -i "$file" -fs "$size"M -c copy "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_replace() {
    local newsound

    echo "Drag the soundfile to this window."
    fn_ask_for_input newsound
    
    #remove possible ' symbols from filepath
    newsound=${newsound//\'/}
    "$FFMPEG" -i "$file" -i "$newsound" -c:v copy -map 0:v:0 -map 1:a:0 "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_crop() {
    local left
    local right
    local top
    local bottom

    echo "Crop how many pixels from the ${cyan}left${white} (leave empty to skip)?"
    fn_ask_for_input left
    echo "Crop how many pixels from the ${cyan}right${white} (leave empty to skip)?"
    fn_ask_for_input right
    echo "Crop how many pixels from the ${cyan}top${white} (leave empty to skip)?"
    fn_ask_for_input top
    echo "Crop how many pixels from the ${cyan}bottom${white} (leave empty to skip)?"
    fn_ask_for_input bottom

    #default to 0 if skipped
    if [ "$left" == "" ]; then left=0; fi
    if [ "$right" == "" ]; then right=0; fi
    if [ "$top" == "" ]; then top=0; fi
    if [ "$bottom" == "" ]; then bottom=0; fi

    "$FFMPEG" -i "$file" -vf "crop=iw-$left-$right:ih-$top-$bottom:$left:$top" "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_concat() {
    local list=("$file")
    local newfile="?"

    while [ "$newfile" != "" ]; do
        echo "Drag another file to this window. Leave empty when done adding files."
        fn_ask_for_input newfile
        if [ "$newfile" != "" ]; then
            #remove possible ' symbols from filepath
            newfile=${newfile//\'/}
            list+=("$newfile")
        fi
    done
    
    #empty the file if it exists
    echo > catlist.tmp
    for element in "${list[@]}"; do
        #fix linux filepaths and print them to file
        element=${element//\/c\//C:\\}; element=${element//\/d\//D:\\}; element=${element//\/e\//E:\\}
        element=${element//\/f\//F:\\}; element=${element//\/g\//G:\\}; element=${element//\/h\//H:\\}
        element=${element//\/i\//I:\\}; element=${element//\/j\//J:\\}; element=${element//\/k\//K:\\}
        element=${element//\/x\//X:\\}; element=${element//\/y\//Y:\\}; element=${element//\/z\//Z:\\}
        element=${element//\//\\}
        echo "file '$element'" >> catlist.tmp
    done

    "$FFMPEG" -f concat -safe 0 -i catlist.tmp -c copy "$outfilepath/new $outfilename" 
    fn_log_created_if_successful "$outfilepath/new $outfilename" 
    rm catlist.tmp
}

fn_speed() {
    local isaudio
    local audiospeed
    local videospeed

    echo "If this is an ${cyan}audio${white} file, type ${cyan}y${white}. Otherwise, type ${cyan}n${white} or leave empty."
    fn_ask_for_input isaudio

    #convert to boolean
    if [ "$isaudio" == "y" ] || [ "$isaudio" == "Y" ]; then isaudio=1; else isaudio=0; fi

    echo "Type a speed. Should be between ${cyan}0.5${white} and ${cyan}2.0${white}."
    fn_ask_for_input audiospeed

    if [ "$isaudio" -eq 1 ]; then
        "$FFMPEG" -i "$file" -filter:a "atempo=$audiospeed" -vn "$outfilepath/new $outfilename"
        fn_log_created_if_successful "$outfilepath/new $outfilename" 
    else
        videospeed=$(awk -v n="$audiospeed" 'BEGIN{printf "%.2f\n", 1/n}')
        "$FFMPEG" -i "$file" -filter_complex "[0:v]setpts=$videospeed*PTS[v];[0:a]atempo=$audiospeed[a]" \
                -map "[v]" -map "[a]" "$outfilepath/new $outfilename"
        fn_log_created_if_successful "$outfilepath/new $outfilename"
    fi
}

fn_resize() {
    local scale

    echo "Type a scale (${cyan}width${white}x${cyan}height${white}, for example ${cyan}720x480${white})."
    echo "Can type ${cyan}-1${white} to keep aspect ratio, for example ${cyan}720x-1${white} or ${cyan}-1x480${white}."
    fn_ask_for_input scale

    #replace x with :
    scale=${scale//x/:}
    "$FFMPEG" -i "$file" -vf scale=$scale "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_volume() {
    local volume

    echo "Type a ratio (example: ${cyan}0.5${white}, ${cyan}2.0${white}, ${cyan}4.0${white})."
    fn_ask_for_input volume

    "$FFMPEG" -i "$file" -filter:a "volume=$volume" "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_text() {
    local fontfile
    local text
    local color
    local size
    local xpos
    local ypos

    echo "Type the name of the font file (example: for Impact, type ${cyan}impact.ttf${white})."
    fn_ask_for_input fontfile
    echo "Type the text to write (no need for quotes)."
    fn_ask_for_input text
    echo "Type the text color (example: ${cyan}blue${white}). Leave empty for white."
    fn_ask_for_input color
    echo "Type the font size (example: ${cyan}24${white})"
    fn_ask_for_input size
    echo "Type the pixel distance from the ${cyan}left${white}. Leave empty for horizontal centering."
    echo "Maximum right is ${cyan}w${white}, can write expressions with it (example: ${cyan}w-250${white})."
    fn_ask_for_input xpos
    echo "Type the pixel distance from the ${cyan}top${white}. Leave empty for vertical centering."
    echo "Maximum bottom is ${cyan}h${white}, can write expressions with it (example: ${cyan}h-250${white})."
    fn_ask_for_input ypos

    #set defaults
    if [ "$color" == "" ]; then color="white"; fi
    if [ "$xpos" == "" ]; then xpos="(w-text_w)/2"; fi
    if [ "$ypos" == "" ]; then ypos="(h-text_h)/2"; fi

    "$FFMPEG" -i "$file" -vf drawtext="fontfile=/Windows/Fonts/$fontfile: text="$text": \
            fontcolor=$color: fontsize=$size: x=$xpos: y=$ypos" -codec:a copy "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_reverse() {
    "$FFMPEG" -i "$file" -vf reverse -af areverse "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_mix() {
    local newsound

    echo "Drag the soundfile to this window."
    fn_ask_for_input newsound
    
    #remove possible ' symbols from filepath
    newsound=${newsound//\'/}
    "$FFMPEG" -i "$file" -i "$newsound" -filter_complex "[0:a][1:a]amerge=inputs=2[a]" \
            -map 0:v -map "[a]" -c:v copy -ac 2 -shortest "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_mute() {
    "$FFMPEG" -i "$file" -c copy -an "$outfilepath/new $outfilename"
    fn_log_created_if_successful "$outfilepath/new $outfilename"
}

fn_menu() {
    local option

    errorflag=0
    fn_ask_for_input option

    case $option in
        1) fn_convert ;;
        2) fn_compress ;;
        3) fn_cut ;;
        4) fn_img ;;
        5) fn_loop ;;
        6) fn_replace ;;
        7) fn_crop ;;
        8) fn_concat ;;
        9) fn_speed ;;
        a | A) fn_resize ;;
        b | B) fn_volume ;;
        c | C) fn_text ;;
        d | D) fn_reverse ;;
        e | E) fn_mix ;;
        f | F) fn_mute ;;
        *)
            echo "Unknown option ${red}'$option'${white}, please retry."
            errorflag=1
            ;;
    esac
}

#do-while loop
fn_menu
while [ "$errorflag" -eq 1 ]; do
    fn_menu
done

echo
read -p "Press any key to close..." -s -n 1
exit 0