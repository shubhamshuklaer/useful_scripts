#!/bin/bash
# http://askubuntu.com/questions/234292/warning-when-available-ram-approaches-zero

# Minimum available memory limit, MB
THRESHOLD=20

# Check time interval, sec
INTERVAL=30

while :
do
    # Needed to make a few changes because the format of free changed in version 3.3.11
    # Arch uses the latest but ubuntu uses 3.3.9 hence this will not work for that..
    # need to use the old script for that
    free=$(free -m|awk '/^Mem:/{print $4}')
    buffers=$(free -m|awk '/^Mem:/{print $6}')
    # cached=$(free -m|awk '/^Mem:/{print $7}')
    cached=$(free -m|awk '/^Mem:/{print $6}')
    # available=$(free -m | awk '/^-\/+/{print $4}')
    available=$(free -m | awk '/^Mem:/{print $7}')
    total=$(free -m | awk '/^Mem:/{print $2}')

    percent_avail=$(($available * 100 / $total))

    message="Percent avail $percent_avail %, Free $free MB, buffers $buffers MB, cached $cached MB, available $available MB"

    if [ $percent_avail -lt $THRESHOLD ]
        then
        notify-send "Memory is running out!" "$message"
    fi

    echo "$message"

    sleep $INTERVAL

done
