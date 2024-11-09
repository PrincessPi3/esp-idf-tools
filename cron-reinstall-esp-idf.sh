#!/bin/bash
# lol 15

function return_status() {
	echo -e "\treturn status: ${?}"
}

echo " === $(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): new reinstall) ==="
echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): sending warning message"
echo 'reinstalling esp-idf in three minutes. save and log out.\n\tmonitor with `tail -f /home/princesspi/esp/install.log`\n\tterminate with `sudo killall cron-reinstall-esp-idf.sh`' | sudo write princesspi
return_status

sleepSecs=3
echo "sleeping ${sleepSecs} seconds"
sleep $sleepSecs
return_status

installDir="${HOME}/esp"
gitBranch=master
runningDir="$( cd "$( dirname "$0" )" && pwd )"
idfDir=$installDir/esp-idf
espressifLocation=$HOME/.espressif
customBinLocation=$installDir/.custom_bin
customBinFrom=$runningDir/custom_bin

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): vars: sleepSecs: $sleepSecs, installDir: $installDir, gitBranch: $gitBranch, runningDir: $runningDir, idfDir: $idfDir, espressifLocation: $espressifLocation, customBinLocation: $customBinLocation, customBinFrom: $customBinFrom"
return_status

if ! [ -d $installDir ]; then
	echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): creating ${installDir}"
	mkdir $installDir
	return_status
fi

if [ -d $idfDir ]; then
	echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): deleting ${idfDir}"
	rm -rf $idfDir
	return_status
fi

if [ -d $espressifLocation ]; then
	echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): deleting ${espressifLocation}"
	rm -rf "${espressifLocation}"
	return_status
fi

if [ -d $customBinLocation ]; then
	echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): deleting ${customBinLocation}"
	rm -rf $customBinLocation
	return_status
fi

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): copying scripts from ${customBinFrom} to ${customBinLocation}"
cp -r $customBinFrom $customBinLocation
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): making scripts executable at ${customBinLocation}"
chmod -R +x $customBinLocation
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): cloning git branch ${gitBranch} with ${gitJobs} jobs to ${idfDir}"
git clone --recursive --single-branch --branch $gitBranch https://github.com/espressif/esp-idf $idfDir
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): installing with ${idfDir}/install.sh all"
eval "${idfDir}/install.sh all"
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): installign tools with idf_tools.py"
python $idfDir/tools/idf_tools.py install all
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): backing up export.sh"
cp $idfDir/export.sh $idfDir/export.sh.bak
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): editing export.sh"
sed -i 's/return 0/# return 0/g' $idfDir/export.sh
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): adding add-to-export-sh.txt to export.ss"
cat $runningDir/add-to-export-sh.txt >> $idfDir/export.sh
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): getting the commit hash"
commitHash=$(git -C $idfDir rev-parse HEAD)
return_status

echo -e "Installed at:\n\t$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)')\n\tat commit ${commitHash}\n\tfrom branch ${gitBranch}\n\tsource: https://github.com/espressif/esp-idf"
echo -e "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)') installed at commit ${commitHash} from branch ${gitBranch}" >> $idfDir/version-data.txt
return_status

echo "rebooting in ${sleepSecs} seconds. seave and log out" | sudo write princesspi
echo "sleeping ${sleepSecs} seconds"
sleep $sleepSecs
return_status

echo "$(date '+%d/%m/%Y-%H.%M.%S %Z (%s)'): sending final message and rebooting";
echo "rebooting NOW bye bye" | sudo write princesspi
return_status

echo -e " === finished ===\n"

echo sudo reboot
