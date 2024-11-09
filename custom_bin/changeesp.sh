subprocess() {
    echo "\nChanging ESPTARGET\n"
    echo "Set esp target (esp32, esp32s3, esp32c6, esp8266, etc)"
    read esp
    eval "$1=$esp"
    return 0
}

ret=''
subprocess ret

export ESPTARGET="${ret}"

echo "\nESPTARGET set to ${ESPTARGET}\n"
echo "\nall done :3\n"