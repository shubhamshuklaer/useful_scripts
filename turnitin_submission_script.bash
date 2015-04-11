#!/bin/bash

#This script combines all files in a given folder with given extension into one combined_file
#and then can also recreate the same dir structure from the same combined_file
#useful for submitting projects on turnitin
#NO GUARANTEE that it will work without fail

##No newline at end of file problem
#The C standard says that text files must end with a
# newline or the data after the last newline may not be read properly.
#According to the POSIX spec for the read command, it should return a
# nonzero status if "End-of-file was detected or an error occurred."
# Since EOF is detected as it reads the last "line", it sets $line
# and then returns an error status, and the error status prevents
# the loop from executing on that last "line".
# The solution is easy: make the loop execute 
#if the read command succeeds OR if anything was read into $line.

working_dir="."
filter_file_name=""
combined_file="combined_file.txt"
action="combine"
filter_string=""
inclusion=0

function parse_filter_file(){
    if [ -n "$filter_file_name" ]
    then
        #cat $filter_file_name | while read line will not work if we want the val of variable which was updated inside loop
        #cause the piplining creates while in a subshell with own set of variables which are destroyed when while is finished

        #See "No newline at end of file problem" on top of file to get the reason why I added the or condition
        while read -r line || [ -n "$line" ]
        do
			#actually the last line can be empty line if there is a newline at end
			if [ -n "$line" ]
			then
				if [ -n "$filter_string" ]
				then
					filter_string="$filter_string -or"
				fi

				filter_string="$filter_string -path \"$working_dir/$line\""
			fi	

        done < "$filter_file_name"

        if [ -n "$filter_string" ]
        then
			if [ "$inclusion" -eq 0 ]
			then
				filter_string=" ! \\( $filter_string \\) "
			else
				filter_string=" \\( $filter_string \\) "
			fi
        fi
    fi
}


function combine(){
    if [ -e "$combined_file" ]
    then
        rm -f "$combined_file"
    fi

    touch "$combined_file"

    #find dir will recursively list all files applying the filter
    #The -I option to grep tells it to ignore binary files and the 
    # -l option tells it to output only file_names the . tells it to match anything
    # since empty files contains no pattern so the are not matched
	# Ignores the empty files
    find_command="find $working_dir -type f $filter_string -exec grep -Il . {} \;"
    #eval is used to execute a string
    find_result=$(eval "$find_command")

	empty_files_find_command="find $working_dir -empty -type f $filter_string"
	empty_files_find_result=$(eval "$empty_files_find_command")

	find_result=$(printf "%s\n%s" "$find_result" "$empty_files_find_result")

    #no quotes on $find_result cause its a list not string
    for entry in $find_result
    do
        if [ -f "$entry" ]
        then
            #same file will have same divise_id and inode number... -L is used to follow link
            if [ "$(stat -L -c "%d:%i" $entry)" != "$(stat -L -c "%d:%i" $combined_file)" ] && [ "$(stat -L -c "%d:%i" $entry)" != "$(stat -L -c "%d:%i" $0)" ]
            then
                echo "$entry"
                #strip the working_dir from the entry
                relative_entry=${entry#$working_dir\/}
                echo "%%%%%%$relative_entry%%%%%%" >> "$combined_file"


                while IFS= read -r line
                do
                    if [[ $line =~ ^%%%%%%(.*)%%%%%%$ ]]
                    then
                        #will strip these that on split-- this is padding 
                        line="@%@%@%@%@%@$line@%@%@%@%@%@"
                    fi
                    echo "$line" >> "$combined_file"
                    line=""
                done < "$entry"

                #See "No newline at end of file problem" on top of file to get the reason why I added this
                #I kept it seperate casue I only wanted to add one extra newline at the end of file and that 
                #is the job of echo "">>"$combined_file" so I used printf so that no new line is added.
                #echo appends newline at end
                if [ -n "$line" ]
                then
                    if [[ $line =~ ^%%%%%%(.*)%%%%%%$ ]]
                    then
                        #will strip these that on split-- this is padding 
                        line="@%@%@%@%@%@$line@%@%@%@%@%@"
                    fi
                    printf "%s" "$line" >> "$combined_file"
                fi

                #Some files have a new line at end and some don't
                #this line will insert a new line after every file so that 
                #the pattern %%%%%% is on a new line
                #while spilitting I will remove 1 newline at end and thus
                #retaining the old state of file
                echo "">>"$combined_file"
            fi
        fi
    done

}

function split(){
    output_file=""
    #In this case, IFS is set to the empty string to prevent read from stripping leading and trailing whitespace from the line.
    #IFS environment variable is set inside loop so that it only acts on read

    while IFS= read -r line
    do
        if [[ $line =~ ^%%%%%%(.*)%%%%%%$ ]]
        then
            if [ -f "$output_file" ]
            then
                #-e option executes perl code from command line only
                #-i option edit in file only
                #-p run the perl code in a loop
                perl -pi -e 'chomp if eof' "$output_file"
            fi
            output_file="${BASH_REMATCH[1]}"
            dir_name=$(dirname "$output_file")
            mkdir -p "$dir_name"
            if [ -e "$output_file" ]
            then
                rm -f "$output_file"
            fi
            touch "$output_file"
            echo "$output_file"
        else
            if [ -n "$output_file" ] #true if var not empty
            then
                if [ -f "$output_file" ]
                then
                    if [[ $line =~ ^@%@%@%@%@%@(%%%%%%.*%%%%%%)@%@%@%@%@%@$ ]]
                    then
                        line="${BASH_REMATCH[1]}"
                    fi
                    echo "$line" >> "$output_file"
                else
                    echo "file$output_file doesn't exist"
                fi
            fi
        fi 
    done < "$combined_file"
    
    #For the last file this has to be done out of loop
    if [ -f "$output_file" ]
    then
        #-e option executes perl code from command line only
        #-i option edit in file only
        #-p run the perl code in a loop
        perl -pi -e 'chomp if eof' "$output_file"
    fi
}


while getopts "d:m:f:a:hi" opt; do
    case $opt in
        d)
            working_dir="$OPTARG"
            ;;
        m)
            filter_file_name="$OPTARG"
            ;;
        f)
            combined_file="$OPTARG"
            ;;
        a)
            action="$OPTARG"
            ;;
		i)
			inclusion=1
			;;
        h)
            echo "Usage"
            echo "First give it executable permission using chmod +x turnitin_submission_script.bash"
            echo "then for execution"
            echo "./turnitin_submission_script.bash [-d dir] [-m filter_file_name] [-f combined_file] [-a action] [-i]"
            echo "action is either spilt or combine"
            echo "with action split arg of -d will act as output dir and arg of -f will act as input combined_file"
            echo "with action combine arg of -d will act as input dir and arg of -f will act as output combined_file"
            echo "combine will recursively combine every file in the dir passed with -d using the filter provided with -m option into a single file"
            echo "split will take the input from combined_file\(-f option\) and split it into the input_dir\(-d option\)"
            echo "preserving the dir structure of the dir which was combined"
            echo "you pass a filter file with -m option\(only for combine action\) it act similar to gitignore file"
            echo "the format of filter_file is you give one ignore exprression on each line you can use shell wildcards basically similar to .gitignore"
            echo "though unlike .gitignore this can only be used to ignore files. Each ignore expression will only reduce or keep same the selected files"
            echo "unlike gitignore where you can add expressions to relax previous expressions"
            echo "all options are optional you can run it with ./turnitin_submission_script.bash"
            echo "the default action will be combine"
            echo "default for -d will be the current working dir"
            echo "default for -f will be combined_file.txt"
            echo "thre is no filter in default so all files will be combined"
            echo "Note that split will replace files with same name so its safer to do it in an empty folder"
            echo "Combine will not combine binary files" 
			echo "-i option will invert the use of filter_file i.e instead of being used as ignoring list it will be used as inclusion list"
			exit 0
            ;;
        \?)
            echo "Invalid syntax"
            echo "use -h for help"
			exit 2
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
