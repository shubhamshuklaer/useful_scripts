#!/bin/bash -i
# http://unix.stackexchange.com/questions/24952/script-to-monitor-folder-for-new-files
# convert all video songs added to mp3
# Music and Videos are bash aliases
Music
mkcd songs
out_dir=`pwd`
Videos
inotifywait -m songs/ -e create -e moved_to |
    while read path action file; do
        echo "The file '$file' appeared in directory '$path' via '$action'"
        out_name=$out_dir"/"${file%.*}".mp3"
        # the quotes arount $file and $out_name is important otherwise it will
        # cause problem when filename has spaces
        # http://mywiki.wooledge.org/BashFAQ/089 the last /dev/null is to
        # prevent ffmpeg to read stdin which it uses for asking questions with yes/no
        ffmpeg -loglevel 8  -i "songs/$file" -f mp3 -ab 192000 -vn "$out_name" </dev/null
        # echo "Converted file :$file to :$out_name"
    done
