#!/bin/bash
# settings
defaultInstallDir="$HOME/esp"

echo -e "\n\nBEGINNING AUTOMATED INSTALL WITH DEFAULTS\n\n"

# possible package manager shit for later
# sudo apt update
# sudo apt install git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

# get the installDir or use default
if [ ! -z $ESPIDFTOOLS_INSTALLDIR ]; then
    echo "envvar ESPIDFTOOLS_INSTALLDIR found! setting install dir to $ESPIDFTOOLS_INSTALLDIR"
    installDir="$ESPIDFTOOLS_INSTALLDIR"
else
    echo "envvar ESPIDFTOOLS_INSTALLDIR not found! using default install dir $defaultInstallDir"
    installDir="$defaultInstallDir"
fi

# detect shell and act accordingly
defShell=$(awk -F: -v user="$(whoami)" '$1 == user {print $NF}' /etc/passwd)

if [[ "$defShell" =~ zsh$ ]]; then
	echo -e "\nSelected zsh shell automatically\n"
	rcFile="$HOME/.zshrc"
elif [[ "$defShell" =~ bash$ ]]; then 
	echo -e "\nSelected bash shell automatically\n"
	rcFile="$HOME/.bashrc"
elif [[ "$defShell" =~ sh$ ]]; then
	rcFile="" # no need for rcFile var when run as cron
else
	echo "unsupported shell $defShell"
	exit
fi

# unset any esp-idf/-tools envvars
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
mkdir -p "$installDir"

# download da tools
git clone --recursive https://github.com/PrincessPi3/esp-idf-tools.git "$installDir/esp-idf-tools"

# do da install
## tryan nuke mode for lulz
bash -c "$installDir/esp-idf-tools/esp-idf-tools-cmd.sh nuke"

echo -e "\n\nINSTALL COMPLETE\n\n"