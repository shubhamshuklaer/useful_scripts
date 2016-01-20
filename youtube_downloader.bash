#!/bin/bash -i
#there is one optional arg which will be passed to -f in youtube-dl

# in getopts the first : disables verbose error reporting
# After than if colon comes after the option it means that it requires an
# argument

format="5"
download_part=false

function usage {
    echo "$0 [-f format] [-s start_time -t duration]"
}

while getopts ":f:s:t:" opt; do
  case $opt in
    f)
        format=$OPTARG
        ;;
    s)
        download_part=true
        start_time=$OPTARG
        ;;
    t)
        download_part=true
        duration=$OPTARG
        ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

cd $(xdg-user-dir DOWNLOAD)

url=$(xclip -o)
body="Url: $url \n Format: $format "
# -n will check for variable not empty
if [[ -n "$start_time" ]]
then
    body="$body \n Start time: $start_time"
fi
if [[ -n "$duration" ]]
then
    body="$body \n Duration time: $duration"
fi

down_url=`youtube-dl -f $format -g $url`
file_name=`youtube-dl -f $format --get-filename $url`

notify-send "Downloading" "$body"
if $download_part
then
    extension="${file_name##*.}"
    base_file_name="${file_name%.*}"
    # http://superuser.com/questions/377343/cut-part-from-video-file-from-start-position-to-end-position-with-ffmpeg
    # -ss must be used before -i for seek see man ffmpeg
    ffmpeg -ss "$start_time" -i "$down_url" -t "$duration" -c copy "$base_file_name""_start=$start_time""_duration=$duration"".$extension"
    ret_val=$?
else
    # pd is a bash function wrapping pycurl-download
    pd "$file_name" "$down_url"
    ret_val=$?
fi

if [[ $ret_val -eq 0 ]]
then
    notify-send "Download Status" "Success"
else
    notify-send "Download Status" "Fail"
fi
