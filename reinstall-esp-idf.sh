#!/bin/bash
set -e # exit on any error

runningDir="$( cd "$( dirname "$0" )" && pwd )"

echo -e "\n===== LFGGGGGGGG ======\n"

echo -e "\nInstalling prerequisites\n"
sudo apt install -y git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

echo -e "\n"

read -p "Enter directory to install/reinstall to (default ${HOME}/esp):" installDir

installDir=${installDir:-$HOME/esp}
idfDir="${installDir}/esp-idf"

echo -e "\nInstalling to ${installDir} esp-idf path will be ${idfDir}\n"

echo -e "\nCleaning up environment\n"
if ! [ -d $installDir ]; then
	echo -e "\n${installDir} not found, creating\n"
	mkdir $installDir
else
	echo -e "\n${installDir} found, skipping delete\n"
fi

if [ -d "${idfDir}" ]; then
	echo -e "\n${idfDir} found, deleting\n"
	rm -rf $idfDir
else
	echo -e "\n${idfDir} not found, skipping delete\n"
fi

if [ -d "${HOME}/.espressif" ]; then
	echo -e "\n${HOME}/.espressif found, deleting\n"
	rm -rf "${HOME}/.espressif"
else
	echo -e "\n${HOME} not found, skipping delete\n"
fi

if [ -d "${installDir}/.custom_bin" ]; then
	echo -e "\n${installDir}/.custom_bin found, deleting\n"
	rm -rf "${installDir}/.custom_bin"
else
	echo -e "\n${installDir}/.custom_bin not found, skipping delete\n"
fi

echo -e "\nPlacing and enabeling custom bins\n"
cp -r .custom_bin $installDir
chmod +x "${installDir}/.custom_bin/*"

echo -e "\nPulling latest esp-idf code from github\n"
git clone --recursive --jobs 5 https://github.com/espressif/esp-idf.git $idfDir

echo -e "\nRunning install script\n"
bash "${idfDir}/install.sh all"

echo -e "\nInstalling optional tools\n"
python "${idfDir}/tools/idf_tools.py install all"

if ! [ -z $(alias | grep get_idf) ]; then
	echo -e "\nget_idf alias not found, appending to ${HOME}/.zshrc\n"
	echo "alias get_idf='. ${idfDir}export.sh'" >> ~/.zshrc
else
	echo -e "\nget_idf alias already installed, skipping\n"
fi

echo -e "\nMaking a backup of ${idfDir}/export.sh to 
${idfDir}/export.sh.bak\n"
cp "${idfDir}/export.sh" "${idfDir}/export.sh.bak"

echo -e "\nEditing ${idfDir}/export.sh\n"
sed -i 's/return 0/# return 0/g' "${idfDir}/export.sh"

echo -e "\nAppending custom additions to ${idfDir}/export.sh\n"
cat "${runningDir}/add-to-export-sh.txt" >> "${idfDir}/export.sh"

echo -e "\nCreating version/commit and date file at ${idfDir}/version-date.txt\n"

datestamp=$(date +"%A, %B %-d %Y at %r %Z (epoch %s)")
commitHash=$(git -C "${idfDir} rev-parse HEAD")
gitBranch=$(git -C "${idfDir} rev-parse --abbrev-ref HEAD")

echo -e "Installed at:\n\t${datestamp}\n\tat commit ${commitHash}\n\tfrom branch ${gitBranch}\n\tsource: https://github.com/espressif/esp-idf" > "${idfDir}/version-data.txt"

echo -e '\nRestart shell with `source ~/.zshrc` and run `get_idf` to use\n'
echo  -e "\nEnjoy your new esp-idf install and environment\n"
echo -e "\nAll done :3\n"
