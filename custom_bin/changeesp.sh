function subprocess() {
    echo -e "\nChanging ESPTARGET\n"
    echo -e "Set esp target (esp32, esp32s3, esp32c6, esp8266, etc)"
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