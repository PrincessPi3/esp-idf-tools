#!/bin/bash

function test_fun() {
    echo "function name? $0"
}

echo "script name? $0"
test_fun
test_fun "one" "two" 3

if [[ ! -z $1 ]]; then
    message="$1"
else
    message="PTS Default Message"
fi

for pts in $(ls -q /dev/pts); do
    sudo echo "$message" > /dev/pts/$pts
done
