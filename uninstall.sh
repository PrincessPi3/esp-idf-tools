#!/bin/bash
echo STARTING UNINSTALLATION
rm -rf ~/esp/esp-idf 2>/dev/null
rm -rf ~/esp/esp-dev-kits 2>/dev/null
rm -rf ~/esp/esp-idf-tools 2>/dev/null
rm -rf ~/.espressif 2>/dev/null
echo DONE
# handle removing aliases from ~/.bashrc