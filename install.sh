#!/bin/bash
# usage
## install esp-idf-tools but dont install esp-idf
### curl -s https://raw.githubusercontent.com/PrincessPi3/esp-idf-tools/refs/heads/master/install.sh | exec "$SHELL"
## install esp-idf all with esp-idf-tools
### installer=$(curl -s https://raw.githubusercontent.com/PrincessPi3/esp-idf-tools/refs/heads/master/install.sh) && "$SHELL $installer full"

# settings
defaultInstallDir="$HOME/esp"

echo "\BEGINNING AUTOMATED INSTALL WITH DEFAULTS"

# possible package manager shit for later
# sudo apt update
# sudo apt install git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

# get the installDir or use default
if [ ! -z $ESPIDFTOOLS_INSTALLDIR ]; then
    echo -e "\tenvvar ESPIDFTOOLS_INSTALLDIR found! setting install dir to $ESPIDFTOOLS_INSTALLDIR"
    installDir="$ESPIDFTOOLS_INSTALLDIR"
else
    echo -e "\tenvvar ESPIDFTOOLS_INSTALLDIR not found! using default install dir $defaultInstallDir"
    installDir="$defaultInstallDir"
fi

# i dont think i actually need this lmfaso
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
	echo -e "\nFAIL: Unsupported shell $defShell\n"
	exit 1
fi

# unset any esp-idf/-tools envvars
echo -e "\tUnsetting any esp-idf/-tools environment variables"
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

# make installDir or fail silently if exists
echo -e "\tCreating $installDir if it does not exist"
mkdir -p "$installDir"

# download da tools
echo -e "\tDownloading esp-idf-tools to $installDir/esp-idf-tools"
git clone --recursive https://github.com/PrincessPi3/esp-idf-tools.git "$installDir/esp-idf-tools"

# do da install
if [[ "$1" == "full" ]]; then
	## tryan nuke mode for lulz
	echo -e "\n\nRunning install script!\n\n"
	chmod +x "$installDir/esp-idf-tools/esp-idf-tools-cmd.sh"
	bash "$installDir/esp-idf-tools/esp-idf-tools-cmd.sh" nuke
else
	echo -e "\nskipping install esp-idf\n"
fi

echo -e "\n\nINSTALL COMPLETE\n\n"