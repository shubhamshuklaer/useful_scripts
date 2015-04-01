#!/bin/bash

#This script combines all files in a given folder with given extension into one combined_file
#and then can also recreate the same dir structure from the same combined_file
#useful for submitting projects on turnitin
#NO GUARANTEE

working_dir="."
filter_file_name=""
combined_file="combined_file.txt"
action="combine"
filter_string=""

function parse_filter_file(){
    filter_string=""
    temp=""
    if [ -n "$filter_file_name" ]
    then
        #cat $filter_file_name | while read line will not work if we want the val of variable which was updated inside loop
        #cause the piplining creates while in a subshell with own set of variables which are destroyed when while is finished
        while read -r line
        do
            if [ -n "$filter_string" ]
            then
                filter_string="$filter_string -or"
            fi
            filter_string="$filter_string -path \"$working_dir/$line\""
        done < "$filter_file_name"

        if [ -n "$filter_string" ]
        then
            filter_string=" ! \\( $filter_string \\) "
        fi
    fi
}


function combine(){
    echo "" > $combined_file

    #find dir will recursively list all files in the system in grep -v is used to invert selection
    find_command="find $working_dir $filter_string"
    #eval is used to execute a string
    find_result=$(eval "$find_command")

    for entry in $find_result
    do
        if [ -f "$entry" ]
        then
            #same file will have same divise_id and inode number... -L is used to follow link
            if [ "$(stat -L -c "%d:%i" $entry)" != "$(stat -L -c "%d:%i" $combined_file)" ] && [ "$(stat -L -c "%d:%i" $entry)" != "$(stat -L -c "%d:%i" $0)" ]
            then
                echo "$entry"
                echo "%%%%%%$entry%%%%%%" >> $combined_file
                echo "">>$combined_file
                cat $entry >>$combined_file
                echo "">>$combined_file
                echo "">>$combined_file
                echo "">>$combined_file
            fi
        fi
    done

}

function split(){
    output_file=""
    cat $combined_file | while read line
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


while getopts "d:m:f:a:" opt; do
    case $opt in
        d)
            working_dir=$OPTARG
            ;;
        m)
            filter_file_name=$OPTARG
            ;;
        f)
            combined_file=$OPTARG
            ;;
        a)
            action=$OPTARG
            ;;
        \?)
            echo "Invalid syntax"
            echo "Usage ./turnitin_submission_script.sh [-d dir] [-m filter_file_name] [-f combined_file] [-a action]"
            echo "extension list is a string with space seperated desired extensions with quote"
            echo "eg\"txt cpp\""
            echo "here only txt and cpp files will be combined"
            echo "action is either spilt or combine"
            echo "with action split arg of -d will act as output dir and arg of -f will act as input combined_file"
            echo "with action combine arg of -d will act as input dir and arg of -f will act as output combined_file"
            echo "you pass a filter file with -m option it act similar to gitignore file"
            echo "the format of filter_file is you give one ignore exprression on each line you can use shell wildcards basically similar to .gitignore"
            echo "though unlike .gitignore this can only be used to ignore files you cannot use negation"
            ;;
    esac
done

#remove the suffix / if present
working_dir=${working_dir%\/}

if [ "$action" == "combine" ]
then
    parse_filter_file
    combine
elif [ "$action" == "split" ]
then
    split
fi
