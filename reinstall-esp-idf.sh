echo "\n===== LFGGGGGGGG ======\n"

echo "\nInstalling prerequisites\n"
sudo apt install -y git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

echo "\nCleaning up environment\n"
if ! [ -d ~/esp ]; then
	echo "\n~/esp not found, creating\n"
	mkdir ~/esp
	else
	echo "\n~/esp found, skipping\n"
fi

if [ -d ~/esp/esp-idf ]; then
	echo "\n~/esp/esp-idf found, deleting\n"
	rm -rf ~/esp/esp-idf
	else
	echo "\n~/esp/esp-idf not found, skipping\n"
fi

if [ -d ~/.espressif ]; then
	echo "\n~/.espressif found, deleting\n"
	rm -rf ~/.espressif
	else
	echo "\n~/.espressif not found, skipping\n"
fi

if [ -d ~/esp/.custom_bin ]; then
	echo "\n~/esp/.custom_bin found, deleting\n"
	rm -rf ~/esp/.custom_bin
fi

echo "\nPlacing and enabeling custom bins\n"
cp -r .custom_bin ~/esp
chmod +x ~/esp/.custom_bin/*

echo "\nPulling latest esp-idf code from github\n"
git clone --recursive --jobs 5 https://github.com/espressif/esp-idf.git ~/esp/esp-idf

echo "\nRunning install script\n"
bash ~/esp/esp-idf/install.sh all

echo "\nInstalling optional tools\n"
python ~/esp/esp-idf/tools/idf_tools.py install all

if ! [ -z $(alias | grep get_idf) ]; then
	echo "\nget_idf alias not found, appending to ~/.zshrc\n"
	echo "alias get_idf='. ~/esp/esp-idf/export.sh'" >> ~/.zshrc
	else
	echo "\nget_idf alias already installed, skipping\n"
fi

echo "\nMaking a backup of ~/esp/esp-idf/export.sh to ~/esp/esp-idf/export.sh.bak\n"
cp ~/esp/esp-idf/export.sh ~/esp/esp-idf/export.sh.bak

echo "\nEditing ~/esp/esp-idf/export.sh\n"
sed -i 's/return 0/# return 0/g' ~/esp/esp-idf/export.sh

echo "\nAppending custom additions to ~/esp/esp-idf/export.sh\n"
cat ./add-to-export-sh.txt >> ~/esp/esp-idf/export.sh

echo '\nRestart shell with `source ~/.zshrc` and run `get_idf` to use\n'
echo  "\nEnjoy your new esp-idf install and environment\n"
echo "\nAll done :3\n"
