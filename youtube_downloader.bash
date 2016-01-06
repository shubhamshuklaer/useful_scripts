#!/bin/bash
#there is one optional arg which will be passed to -f in youtube-dl
cd $(xdg-user-dir DOWNLOAD)
if [[ $# -eq 1 ]]
then
    format=$1
else
    format="5"
fi
url=$(xclip -o)
notify-send "Downloading" "Url: $url \n Format: $format"
eval "youtube-dl -f $format $url"
if [[ $? -eq 0 ]]
then
    notify-send "Download Status" "Success"
else
    notify-send "Download Status" "Fail"
fi
