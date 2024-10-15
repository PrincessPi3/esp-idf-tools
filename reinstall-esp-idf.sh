echo "===== LFGGGGGGGG ======"

echo "Setting up environment"
current_dir=$PWD

echo "cleaning up environment"
if ! [ -d ~/esp ]; then
	echo "~/esp not found, creating\n"
	mkdir ~/esp
	else
	echo "~/esp found, skipping\n"
fi

if [ -d ~/esp/esp-idf ]; then
	echo "~/esp/esp-idf found, deleting\n"
	rm -rf ~/esp/esp-idf
	else
	echo "~/esp/esp-idf not found, skipping\n"
fi

if [ -d ~/.espressif ]; then
	echo "~/.espressif found, deleting\n"
	rm -rf ~/.espressif
	else
	echo "~/.espressif not found, skipping\n"
fi

if [ -d ~/esp/.custom_bin ]; then
	echo "~/esp/.custom_bin found, deleting\n"
	rm -rf ~/esp/.custom_bin
fi

echo "\n\nPlacing and enablig custom bins\n\n"
cp -r .custom_bin ~/esp
chmod +x ~/esp/.custom_bin/*

echo "\n\nPulling latest esp-idf code from github\n\n"
git clone --recursive --jobs 5 https://github.com/espressif/esp-idf.git ~/esp/esp-idf

echo "\n\nRunning install script\n\n"
~/esp/esp-idf/install.sh all --enable-*

echo "\n\nInstalling optional tools\n\n"
python ~/esp/esp-idf/tools/idf_tools.py install all

if ! [ -z $(alias | grep get_idf) ]; then
	echo "get_idf alias not found, appending to ~/.zshrc\n"
	echo "alias get_idf='. ~/esp/esp-idf/export.sh'" >> ~/.zshrc
	else
	echo "get_idf alias already installed, skipping\n"
fi

echo "Making copy of ~/esp/esp-idf/export.sh to ~/esp/esp-idf/export.sh.bak\n"
cp ~/esp/esp-idf/export.sh ~/esp/esp-idf/export.sh.bak

echo "editing ~/esp/esp-idf/export.sh\n"
sed -i 's/return 0/# return 0/g' ~/esp/esp-idf/export.sh

echo "appending custom additions to ~/esp/esp-idf/export.sh\n"
cat $current_dir/add-to-export-sh.txt >> ~/esp/esp-idf/export.sh

echo 'Restart shell with `source ~/.zshrc` and run `get_idf` to use\n'
echo "All done :3 Enjoy your new esp-idf install and environment"
