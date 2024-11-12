#!/bin/bash
# script to replace the .custom_bins and add-to-expport.txt without other reinstall

runningDir="$( cd "$( dirname "$0" )" && pwd )"
scriptVers=$(cat $runningDir/version.txt) # make sure version.txt does NOT have newline

echo -e "Retoolan~ Version: "

echo -e "\ndeleting old export.sh\n"
rm $HOME/esp/esp-idf/export.sh # ~/esp/esp-idf/export.sh.bak.2

echo -e "\nReplacing original export.sh from export.sh.bak\n"
cp $HOME/esp/esp-idf/export.sh.bak $HOME/esp/esp-idf/export.sh

echo -e "\nAppending new add-to-export-sh.txt to export.sh\n"
cat $runningDir/add-to-export-sh.txt >> $HOME/esp/esp-idf/export.sh

echo -e "\nDeleting .custom_bins dir\n"
rm -rf $HOME/esp/.custom_bin

echo -e "\nCoppying new custom_bins and making them executable\n"
cp -r $runningDir/custom_bins ~/esp/.custom_bins
chmod +x $HOME/esp/.custom_bins/*

echo -e "\nAll done :3\n"