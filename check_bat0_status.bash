#!/bin/bash -i

#check_battery is an alias form my bash_aliases

percentage=`check_battery | awk '/.*percentage.*/ {print $2}'`
# need to change the delimiter casuse when using space as delimeter
# "time" is first column then second column is "to" and so on
time_to=`check_battery | awk -F ":" '/.*time to.*/ {print $2}'`
# Remove trailing space
# http://www.cyberciti.biz/faq/bash-remove-whitespace-from-string/
time_to=${time_to##*( )}
# Replace minutes and hours to make output shorter
# http://www.thegeekstuff.com/2010/07/bash-string-manipulation/
time_to=${time_to//minutes/mins}
time_to=${time_to//hours/hrs}
state=`check_battery | awk '/.*state.*/ {print $2}'`

if [ $state  == "fully-charged" ]
then
    echo "Full"
else
    # showing only first character for state
    echo "$percentage(${state:0:1})($time_to)"
fi
