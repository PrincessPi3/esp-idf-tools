#!/bin/bash
# settings
defaultInstallDir="$HOME/esp"

echo "STARTING UNINSTALLATION"

# get the installDir or use default
if [ ! -z $ESPIDFTOOLS_INSTALLDIR ]; then
    echo -e "\tenvvar ESPIDFTOOLS_INSTALLDIR found! setting install dir to $ESPIDFTOOLS_INSTALLDIR"
    installDir="$ESPIDFTOOLS_INSTALLDIR"
else
    echo -e "\tenvvar ESPIDFTOOLS_INSTALLDIR not found! using default install dir $defaultInstallDir"
    installDir="$defaultInstallDir"
fi

# detect shell and act accordingly
defShell=$(awk -F: -v user="$(whoami)" '$1 == user {print $NF}' /etc/passwd)
if [[ "$defShell" =~ zsh$ ]]; then
	echo -e "\tSelected zsh shell automatically"
	rcFile="$HOME/.zshrc"
elif [[ "$defShell" =~ bash$ ]]; then 
	echo -e "\tSelected bash shell automatically"
	rcFile="$HOME/.bashrc"
elif [[ "$defShell" =~ sh$ ]]; then
	rcFile="" # no need for rcFile var when run as cron
else
	echo "FAIL: Unsupported shell $defShell"
	exit 1
fi

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

# nuke dirs and supress errors
echo -e "\tRemoving directories"
rm -rf "$installDir/esp-idf" 2>/dev/null
rm -rf "$installDir/esp-dev-kits" 2>/dev/null
rm -rf "$installDir/esp-idf-tools" 2>/dev/null
rm -rf "$installDir/.espressif" 2>/dev/null

# nuke logs and supress errors
echo -e "\tRemoving log files"
rm -f "$installDir/install.log" 2>/dev/null
rm -f "$installDir/version-data.log" 2>/dev/null

# cleanup $rcFile
echo -e "\tCleaning up $rcFile"
sed -i.bak '/# esp-idf-tools/d' "$rcFile" # with first one, maek a backup
sed -i '/ESPIDFTOOLS_INSTALLDIR/d' "$rcFile"
sed -i '/get-esp-tools/d' "$rcFile"
sed -i '/run-esp-cmd/d' "$rcFile"
sed -i '/esp-install-monitor/d' "$rcFile"
sed -i '/esp-install-logs/d' "$rcFile"
## remove leading and trailing newlines in $rcFile in place
printf "%s" "$(cat $rcFile)" > "$rcFile"

echo "DONE UNINSTALLING"