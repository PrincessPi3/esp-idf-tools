#!/bin/bash
if [[ ! -z $1 ]]; then
    message="$1"
else
    message="PTS Default Message"
fi

for pts in $(ls -q /dev/pts); do
    sudo echo "$message" > /dev/pts/$pts
done
