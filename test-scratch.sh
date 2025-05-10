#!/bin/bash
# function subprocess() {
#     targets=$(idf.py --list-targets)
#     out=''
# 
#     for target in $targets; do
#         out="$out $target"
#     done
# 
#     eval "$1=$out"
# 
#     return 0
# }

function getTargets() {
    tmpFile='/tmp/targets.tmp'
    idf.py --list-targets > "$tmpFile"
    tr '\n' ' ' < "$tmpFile"
    rm "$tmpFile"
}

targs=$(getTargets)

echo $targs
# ret=''
# subprocess ret

# echo "$ret"