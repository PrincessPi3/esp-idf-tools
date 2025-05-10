function subprocess() {
    echo -e "\nChanging ESPTARGET\n"
    echo -e "Set esp target (one of esp32, esp32s2, esp32c3, esp32s3, esp32c2, esp32c6, esp32h2, esp32p4, esp32c5, esp32c61, or linux)"
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