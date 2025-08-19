#!/bin/bash
echo "STARTING UNINSTALLATION"

# unset any esp-idf/-tools envvars
echo -e "\tUnsetting environment variables"
unset ESPIDFTOOLS_INSTALLDIR
unset IDF_PATH
unset ESP_IDF_VERSION
unset IDF_PYTHON_ENV_PATH
unset OPENOCD_SCRIPTS
unset ESP_ROM_ELF_DIR
unset IDF_DEACTIVATE_FILE_PATH
unset IDF_TOOLS_INSTALL_CMD
unset IDF_TOOLS_EXPORT_CMD
unset ESPPORT
unset ESPBAUD
unset ESPTARGET

# nuke dirs
echo -e "\tRemoving directories"
rm -rf ~/esp/esp-idf 2>/dev/null
rm -rf ~/esp/esp-dev-kits 2>/dev/null
rm -rf ~/esp/esp-idf-tools 2>/dev/null
rm -rf ~/.espressif 2>/dev/null

# nuke logs
echo -e "\tRemoving log files"
rm -f ~/esp/install.log 2>/dev/null
rm -f ~/esp/version-data.log 2>/dev/null

# cleanup ~/.bashrc
## with first one, make a backup
## after dat, no backups
echo -e "\tCleaning up ~/.bashrc"
sed -i.bak '/# esp-idf-tools/d' ~/.bashrc
sed -i '/get-esp-tools/d' ~/.bashrc
sed -i '/run-esp-cmd/d' ~/.bashrc
sed -i '/esp-install-monitor/d' ~/.bashrc
sed -i '/esp-install-logs/d' ~/.bashrc

echo "DONE UNINSTALLING"