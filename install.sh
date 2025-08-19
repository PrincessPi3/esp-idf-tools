#!/bin/bash
mkdir -p ~/esp
git clone --recursive https://github.com/PrincessPi3/esp-idf-tools.git ~/esp/esp-idf-tools
bash ~/esp/esp-idf-tools/esp-idf-tools-cmd.sh install install