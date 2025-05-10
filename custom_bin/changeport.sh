function subprocess() {
    echo -e "\nChanging ESPPORT\n"
    echo -e "\nChecking for Serial Devices in dmesg\n"
    COUNTER=0
    devarr=()
    for line in $(dmesg | tail -50 | grep -o -E "tty[A-Z]{3}[0-9]{0,2}" | sort -u); do
                    echo -e "$COUNTER  /dev/$line"
                    devarr+=("/dev/$line")
                    COUNTER=$((COUNTER+1))
    done
    
    if [ $COUNTER -gt 0 ]; then
        echo -e "\nEnter TTY Number You'd Like:"
        read tty
        ttyselect=$devarr[(($tty+1))]
    else 
        echo -e "\nNo Serial Devices Found, Select one later with 'changeport'\n"
fi

    sel=$tty+1
    eval "$1=$devarr[$sel]"

    return 0
} 

if [ ! -z "$1" ]; then
    ret="$1"
else
    ret=''
    subprocess ret
fi

export ESPPORT=$ret

echo -e "\nESPPORT set to $ESPPORT\n"
echo -e "\nAll done :3\n"