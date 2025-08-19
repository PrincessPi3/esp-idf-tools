#!/bin/bash
echo STARTING UNINSTALLATION
# nuke dirs
rm -rf ~/esp/esp-idf 2>/dev/null
rm -rf ~/esp/esp-dev-kits 2>/dev/null
rm -rf ~/esp/esp-idf-tools 2>/dev/null
rm -rf ~/.espressif 2>/dev/null

# nuke logs
rm -f ~/esp/install.log 2>/dev/null
rm -f ~/esp/version-data.log 2>/dev/null

# cleanup ~/.bashrc
# with first one, make a backup
sed -i.bak '/# esp-idf-tools/d' ~/.bashrc
sed -i '/get-esp-tools/d' ~/.bashrc
sed -i '/run-esp-cmd/d' ~/.bashrc
sed -i '/esp-install-monitor/d' ~/.bashrc
sed -i '/esp-install-logs/d' ~/.bashrc