subprocess() {
    echo "\nChanging ESPPORT\n"
    echo "TTY devices found in dmesg:"
    COUNTER=0
    devarr=()
    for line in $(dmesg | tail -50 | grep -o -E "tty[A-Z]{3}[0-9]{0,2}" | sort -u); do
                    echo "$COUNTER  /dev/$line"
                    devarr+=("/dev/$line")
                    COUNTER=$((COUNTER+1))
    done

    echo "\nEnter TTY Number You'd Like:"
    read tty

    sel=$tty+1
    eval "$1=$devarr[$sel]"

    return 0
} 

ret=''
subprocess ret

export ESPPORT=$ret

echo "\nESPPORT set to ${ESPPORT}\n"
echo "\nAll done :3\n"