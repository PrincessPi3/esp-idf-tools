function getTargets() {
    tmpFile='/tmp/targets.tmp'
    idf.py --preview --list-targets > "$tmpFile"
    tr '\n' ' ' < "$tmpFile"
    rm "$tmpFile"
}

function subprocess() {
    echo -e "\nChanging ESPTARGET\n"
    echo -e "Set esp target (one of $(getTargets))"
    read esp
    eval "$1=$esp"
    return 0
}

if [ ! -z "$1" ]; then
    ret="$1"
else
    ret=''
    subprocess ret
fi

export ESPTARGET="${ret}"

echo -e "\nESPTARGET set to $ESPTARGET\n"
echo -e "\nAll done :3\n"