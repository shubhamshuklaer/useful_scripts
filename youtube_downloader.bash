#!/bin/bash
cd $(xdg-user-dir DOWNLOAD)
youtube-dl -f 5 $(xclip -o)
if [[ $? -eq 0 ]]
then
    notify-send "Download Status" "Success"
else
    notify-send "Download Status" "Fail"
fi
