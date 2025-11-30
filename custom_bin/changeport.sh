#!/bin/bash

# handle manuallyy fiven
if [ ! -z "$1" ]; then
    export ESPPORT="$1"
    echo "ESPPORT set to $ESPPORT"
    return
fi

# gloals
COUNTER=0
declare -a devarr

# hunt dmesg for tty funss and maek da selector thng
for line in $(dmesg | tail -50 | grep -o -E "tty[A-Z]{3}[0-9]{0,2}" | sort -u); do
    echo -e "$COUNTER  /dev/$line"
    devarr[$COUNTER]="/dev/$line"
    COUNTER=$(($COUNTER+1))
done

# get dat bynverr
if [ $COUNTER -gt 0 ]; then
    echo -e "\nEnter TTY Number You'd Like:"
    read tty
    ttyselect="${devarr[$tty]}"
else
    echo -e "\nNo Serial Devices Found, Select one later with 'changeport'\n"
fi

# finally expport
export ESPPORT="$ttyselect"
echo "ESPPORT set to $ESPPORT"
