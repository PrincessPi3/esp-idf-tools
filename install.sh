#!/bin/bash
# sudo apt update
# sudo apt install git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0
mkdir -p ~/esp
git clone --recursive https://github.com/PrincessPi3/esp-idf-tools.git ~/esp/esp-idf-tools
bash ~/esp/esp-idf-tools/esp-idf-tools-cmd.sh # run as default noninteractive mode