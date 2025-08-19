#!/bin/bash
rcFile=~/.bashrc

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

# cleanup $rcFile
echo -e "\tCleaning up $rcFile"
sed -i.bak '/# esp-idf-tools/d' $rcFile # with first one, maek a backup
sed -i '/ESPIDFTOOLS_INSTALLDIR/d' $rcFile
sed -i '/get-esp-tools/d' $rcFile
sed -i '/run-esp-cmd/d' $rcFile
sed -i '/esp-install-monitor/d' $rcFile
sed -i '/esp-install-logs/d' $rcFile
printf "%s" "$(cat $rcFile)" > $rcFile # remove leading and trailing newlines in place

echo "DONE UNINSTALLING"