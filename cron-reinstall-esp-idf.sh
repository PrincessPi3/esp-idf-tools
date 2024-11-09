#!/bin/bash
startTime=$(date '+%s')

# testing:
# 	rm ~/esp/install.log
# 	bash ~/esp/esp-install-custom/cron-reinstall-esp-idf.sh
# 	tail -f -n 50 ~/esp/install.log

# cron:
# 	crontab -e
# 	0 8 * * * bash $HOME/esp/esp-install-custom/cron-reinstall-esp-idf.sh

cronVers=38-live # version of this script
sleepMins=3 # minutes of warning to wait for user to log out
log=$HOME/esp/install.log

myUser=$USER

function return_status() {
	strii="\treturn status: ${?}"
	echo -e $strii
	echo -e $strii >> $log
}

function write_to_log() {
	echo -e "$1\n"
	echo -e "$1\n" >> $log
}

function logout_all_users() {
	who | sudo awk '$1 !~ /root/{ cmd="/usr/bin/pkill -KILL -u " $1; system(cmd)}'
	return $?
}

sleepSecs=$((sleepMins*60)) # calculated seconds of warning to wait for user to log out

write_to_log " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): new reinstall ==="
write_to_log "Cron version: ${cronVers}"

warningString="\nWARNING:\n\tReinstalling esp-idf in ${sleepSecs} minutes! You will be force logged out in ${sleepSecs} minutes! Save and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall cron-reinstall-esp-idf.sh\`\n\t$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')\n"

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sending warning message to $myUser"
write_to_log "$warningString"
echo -e "$warningString" | sudo write $myUser
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sleeping ${sleepSecs} minutes"
sleep $sleepSecs
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): force logging out all users"
logout_all_users
return_status

gitJobs=4
installDir=$HOME/esp
gitBranch=master
runningDir="$( cd "$( dirname "$0" )" && pwd )"
idfDir=$installDir/esp-idf
espressifLocation=$HOME/.espressif
customBinLocation=$installDir/.custom_bin
customBinFrom=$runningDir/custom_bin

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')\nvars:\n\tmyUser: $myUser\n\tcronVers: $cronVers\n\tgitJobs: $gitJobs\n\tlog: $log\n\tsleepSecs: $sleepSecs\n\tinstallDir: $installDir\n\tgitBranch: $gitBranch\n\trunningDir: $runningDir\n\tidfDir: $idfDir\n\tespressifLocation: $espressifLocation\n\tcustomBinLocation: $customBinLocation\n\tcustomBinFrom: $customBinFrom"
return_status

if ! [ -d $installDir ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): creating ${installDir}"
	mkdir $installDir
	return_status
fi

if [ -d $idfDir ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${idfDir}"
	rm -rf $idfDir
	return_status
fi

if [ -d $espressifLocation ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${espressifLocation}"
	rm -rf "${espressifLocation}"
	return_status
fi

if [ -d $customBinLocation ]; then
	write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${customBinLocation}"
	rm -rf $customBinLocation
	return_status
fi

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): copying scripts from ${customBinFrom} to ${customBinLocation}"
cp -r $customBinFrom $customBinLocation
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): making scripts executable at ${customBinLocation}"
chmod -R +x $customBinLocation
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): cloning git branch ${gitBranch} with ${gitJobs} jobs to ${idfDir}"
git clone --recursive --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing with ${idfDir}/install.sh all"
eval "${idfDir}/install.sh all"
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing tools with idf_tools.py"
python $idfDir/tools/idf_tools.py install all
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): backing up export.sh"
cp $idfDir/export.sh $idfDir/export.sh.bak
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): editing export.sh"
sed -i 's/return 0/# return 0/g' $idfDir/export.sh
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): adding add-to-export-sh.txt to export.ss"
cat $runningDir/add-to-export-sh.txt >> $idfDir/export.sh
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): getting the commit hash"
commitHash=$(git -C $idfDir rev-parse HEAD)
return_status

gitDataLog="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installed esp-idf from commit $commitHash from branch $gitBranch using $cronVers"
write_to_log $gitDataLog
echo -e $gitDataLog >> $installDir/version-data.txt
return_status

rebootMsg="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): rebooting in ${sleepSecs} minutes. seave and log out"
write_to_log $rebootMsg
echo $rebootMsg | sudo write princesspi
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sleeping ${sleepSecs} minutes"
sleep $sleepSecs
return_status

write_to_log "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): force logging out all users"
logout_all_users
return_status

endTime=$(date '+%s')
timeElapsed=$(($endTime-$startTime))
write_to_log "reinstall completed in $timeElapsed seconds"

write_to_log " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): finished ===\n"

sudo reboot
