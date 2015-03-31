#!/bin/bash

#This script combines all files in a given folder with given extension into one file
#and then can also recreate the same dir structure from the same file
#useful for submitting projects on turnitin
#NO GUARANTEE

working_dir="."
extension_list=""
file="file.txt"
action="combine"


function combine(){
    echo "" > $file

    for entry in $(find "$working_dir")
    do
        if [ -f "$entry" ]
        then
            if [ "$(stat -L -c "%d:%i" $entry)" != "$(stat -L -c "%d:%i" $file)" ] && [ "$(stat -L -c "%d:%i" $entry)" != "$(stat -L -c "%d:%i" $0)" ] && [ "$(stat -L -c "%d:%i" $entry)" != "$(stat -L -c "%d:%i" $working_dir)" ]
            then
                file_ext=${entry##*.}
                if [[ $extension_list =~ $file_ext ]]
                then

                    echo "%%%%%%$entry%%%%%%" >> $file
                    echo "">>$file
                    cat $entry >>$file
                    echo "">>$file
                    echo "">>$file
                    echo "">>$file
                fi
            fi
        fi
    done

}

function split(){
    output_file=""
    cat $file | while read line
    do
        if [[ $line =~ ^%%%%%%(.*)%%%%%%$ ]]
        then
            output_file="${BASH_REMATCH[1]}"
            dir_name=$(dirname "$output_file")
            mkdir -p "$dir_name"
            touch "$output_file"
        else
            if [ -n $output_file ] #true if var not empty
            then
                echo "$line" >> "$output_file"
            fi
        fi 
    done
}


while getopts "d:e:f:a:" opt; do
    case $opt in
        d)
            working_dir=$OPTARG
            ;;
        e)
            extension_list=$OPTARG
            ;;
        f)
            file=$OPTARG
            ;;
        a)
            action=$OPTARG
            ;;
        \?)
            echo "Invalid syntax"
            echo "Usage ./turnitin_submission_script.sh [-d dir] [-e extension_list] [-f file] [-a action]"
            echo "extension list is a string with space seperated desired extensions with quote"
            echo "eg\"txt cpp\""
            echo "here only txt and cpp files will be combined"
            echo "action is either spilt or combine"
            echo "with action split arg of -d will act as output dir and arg of -f will act as input file"
            echo "with action combine arg of -d will act as input dir and arg of -f will act as output file"
            ;;
    esac
done

if [ "$action" == "combine" ]
then
    combine
elif [ "$action" == "split" ]
then
    split
fi
