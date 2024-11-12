#!/bin/bash
set -e # for testan, die on error

# redo these notes:
# testing:
# 	bash $HOME/esp/esp-install-custom/cron-reinstall-esp-idf.sh test
# 	tail -f -n 50 $HOME/esp/install.log
# 	ls $HOME/esp; echo "install.log"; cat $HOME/esp/install.log;  echo "version-data.txt"; cat $HOME/esp/version-data.txt

# delete logs:
#	 rm  -f $HOME/esp/install.log; rm -f $HOME/esp/version-data.txt

# cron:
# 	crontab -e
# 	0 8 * * * bash $HOME/esp/esp-install-custom/cron-reinstall-esp-idf.sh

myUser=princesspi
gitJobs=5
installDir=/home/$myUser/esp
log=$installDir/install.log
versionData=$installDir/version-data.txt
gitBranch=master
idfDir=$installDir/esp-idf
espressifLocation=$HOME/.espressif
customBinLocation=$installDir/.custom_bin
runningDir="$( cd "$( dirname "$0" )" && pwd )"
customBinFrom=$runningDir/custom_bin
# cronVers=55-dev.3 # version of this script
scriptVers=$(cat $runningDir/version.txt) # make sure version.txt does NOT have newline
arg=$1

function returnStatus() {
	strii="\treturn status: ${?}"
	echo -e "$strii\n"
	echo -e "$strii\n" >> $log
}

function writeToLog() {
	echo -e "$1"
	echo -e "$1" >> $log
}

function sleepHold() {
	sleepSecs=$((sleepMins*60)) # calculated seconds of warning to wait for user to log out

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sleeping ${sleepMins} minutes"
	sleep $sleepSecs
	returnStatus
}

function handleCustomBins() {
	if [ -d $customBinLocation ]; then
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${customBinLocation}"
		rm -rf $customBinLocation
		returnStatus
	fi

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): copying scripts from ${customBinFrom} to ${customBinLocation}"
	cp -r $customBinFrom $customBinLocation
	returnStatus

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): making scripts executable at ${customBinLocation}"
	chmod -R +x $customBinLocation
	returnStatus
}

function handleExport() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): backing up ${idfDir}/export.sh to ${idfDir}/export.sh.bak"
	cp $idfDir/export.sh $idfDir/export.sh.bak
	returnStatus
	
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): editing ${idfDir}/export.sh"
	sed -i 's/return 0/# return 0/g' $idfDir/export.sh
	returnStatus
	
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): adding ${runningDir}/add-to-export-sh.txt to ${idfDir}/export.sh"
	cat $runningDir/add-to-export-sh.txt >> $idfDir/export.sh
	returnStatus
}

function handleSetupEnvironment() {
	if ! [ -d $installDir ]; then
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): creating ${installDir}"
		mkdir $installDir
		returnStatus
	fi

	if [ -d $idfDir ]; then
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${idfDir}"
		rm -rf $idfDir
		returnStatus
	fi

	if [ -d $espressifLocation ]; then
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${espressifLocation}"
		rm -rf "${espressifLocation}"
		returnStatus
	fi
}

function handleDownloadInstall() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): cloning git branch ${gitBranch} with ${gitJobs} jobs to ${idfDir}"
	eval "$gitCmd"
	returnStatus

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing with ${idfDir}/install.sh all"
	eval "$installCmd"
	returnStatus

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing tools with python ${idfDir}/tools/idf_tools.py install all"
	eval "$toolsInstallCmd"
	returnStatus

	# check up on if dis be workan
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): getting the commit hash"
	commitHash=$(git -C $idfDir rev-parse HEAD)
	returnStatus

	gitDataLog="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installed esp-idf from commit $commitHash from branch $gitBranch using $scriptVers"
	writeToLog "$gitDataLog"
	echo -e "$gitDataLog" >> $versionData
	returnStatus
}

handleReboot() {
	rebootMsg="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): rebooting in $sleepMins minutes. save and log out"
	writeToLog "$rebootMsg"
	# warn_all_users "$rebootMsg"
	echo "$rebootMsg" | sudo write "$myUser"
	returnStatus
}

function handleWarn() {
	warningString="WARNING:\n\tReinstalling esp-idf in ${sleepMins} minutes! You will be force logged out in ${sleepMins} minutes! Save and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall cron-reinstall-esp-idf.sh\`\n\t$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')"
	writeToLog $warningString

	sleepHold

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Force logging out ${myUser}"

	echo -e "$warningString" | sudo write "$myUser"
	returnStatus
}

function handleLogoutAllUsers() {
	handleWarn

	# logout all users
	who | sudo awk '$1 !~ /root/{ cmd="/usr/bin/loginctl terminate-user " $1; system(cmd)}'
	returnStatus
}

function handleStart() {
	startTime=$(date '+%s')

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')\nvars:\n\tmyUser: $myUser\n\tscriptVers: $scriptVers\n\tversionData: $versionData\n\tlog: $log\n\tsleepMins: $sleepMins\n\tsleepSecs: $sleepSecs\n\tinstallDir: $installDir\n\tgitJobs: $gitJobs\n\tgitBranch: $gitBranch\n\tgitCmd: $gitCmd\n\trunningDir: $runningDir\n\tidfDir: $idfDir\n\tespressifLocation: $espressifLocation\n\tcustomBinLocation: $customBinLocation\n\tcustomBinFrom: $customBinFrom\n\tinstallCmd: $installCmd\n\ttoolsInstallCmd: $toolsInstallCmd"

	writeToLog " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): new ${action} ==="
	writeToLog "Version: ${scriptVers}"
}

function handleEmptyLogs() {
 	rm -f $log
 	touch $log
 
 	rm -f $versionData
 	touch $versionData
}

function handleEnd() {
	endTime=$(date '+%s')
	timeElapsed=$(($endTime-$startTime))

	writeToLog "reinstall completed in $timeElapsed seconds"
	writeToLog " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): finished ===\n\n"
}

# full order:
# handleStart
# handleWarn
# sleepHold
# handleLogoutAllUsers
# handleSetupEnvironment
# handleCustomBins
# handleDownloadInstall
# handleExport
# handleWarn
# sleepHold
# handleEnd
# handleReboot
# exit


if [ "$arg" == "test" ]; then
 	action="TEST"
 
 	gitCmd="echo git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"

 	installCmd="echo $idfDir/install.sh all"
 	
	toolsInstallCmd="echo python $idfDir/tools/idf_tools.py install all"

	sleepMins=0

	handleStart
	handleLogoutAllUsers
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleEnd
	exit

elif [ "$arg" == "nologout" ]; then
	action="REINSTALL (NOLOGOUT)"
	
 	gitCmd="git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"

 	installCmd="$idfDir/install.sh all"
 	
	toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"

	handleStart
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleEnd
	exit

elif [ "$arg" == "retool" ]; then
	action="RETOOL"

	handleStart
	handleCustomBins
	handleExport
	handleEnd
	exit

else # full install with warn, sleep, and reboot
	action="REINSTALL (DEFAULT)"
	
 	gitCmd="git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"

 	installCmd="$idfDir/install.sh all"
 	
	toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"

	handleStart
	handleLogoutAllUsers
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleLogoutAllUsers
	handleEnd
	handleReboot
	exit
fi

# startTime=$(date '+%s')

# 	if [ "$arg" == "test" ]; then
# 		# rm -f $log
# 		# touch $log
# 		# 
# 		# rm -f $versionData
# 		# touch $versionData
# 	else
# 		handleReboot
# 	fi
# }

# function warn_all_users() {
# 	who | sudo awk '$1 !~ /root/{ cmd="echo '$1' | /usr/bin/write " $1; system(cmd)}'
#}

# 	# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): NOLOGOUT mode"
# 	action="REINSTALL (NOLOGOUT)"
# 
# 	sleepMins=0 # minutes of warning to wait for user to log out
# 
# 	gitCmd="git clone --recursive --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
# 	installCmd="$idfDir/install.sh all"
# 	toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"
# 
# 	function logout_all_users() {
# 		return 0;
# 	}
# elif [ "$arg" == "retool" ]; then
# 	action="RETOOL"
# 
# 	writeToLog " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): new ${action} ==="
# 	writeToLog "Version: ${scriptVers}"
# 
# 	writeToLog "deleting old export.sh"
# 	rm $idfDir/export.sh
# 	returnStatus
# 
# 	writeToLog "Replacing original export.sh from export.sh.bak"
# 	cp $idfDir/export.sh.bak $idfDir/export.sh
# 	returnStatus
# 
# 	writeToLog "Editing ${idfDir}/export.sh"
# 	sed -i 's/return 0/# return 0/g' $idfDir/export.sh
# 	returnStatus
# 
# 	writeToLog "Appending new add-to-export-sh.txt to export.sh"
# 	cat $runningDir/add-to-export-sh.txt >> $idfDir/export.sh
# 	returnStatus
# 
# 	handleCustomBins
# 
# 	# writeToLog "Deleting .custom_bin dir"
# 	# rm -rf $customBinLocation
# 	# returnStatus
# # 
# 	# writeToLog "Coppying new custom_bin and making them executable"
# 	# cp -r $customBinFrom $customBinLocation
# 	# chmod +x $customBinLocation/*
# 	# returnStatus
# 
# 	exit
# else
# 	# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): LIVE mode"
# 
# 	sleepMins=3 # minutes of warning to wait for user to log out
# 
# 	gitCmd="git clone --recursive --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
# 	installCmd="$idfDir/install.sh all"
# 	toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"
# 
# 	function logout_all_users() {
# 		who | sudo awk '$1 !~ /root/{ cmd="/usr/bin/loginctl terminate-user " $1; system(cmd)}'
# 		return $?
# 	}
# fi
# 
# writeToLog " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): new ${action} ==="
# writeToLog "Version: ${scriptVers}"

# sleepSecs=$((sleepMins*60)) # calculated seconds of warning to wait for user to log out

# warningString="\nWARNING:\n\tReinstalling esp-idf in ${sleepMins} minutes! You will be force logged out in ${sleepMins} minutes! Save and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall cron-reinstall-esp-idf.sh\`\n\t$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')"

# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sending warning message to $myUser"
# writeToLog "$warningString"
# echo -e "$warningString" | sudo write "$myUser"
# # warn_all_users "$warningString"
# returnStatus

# sleepHold

# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): force logging out all users"
# logout_all_users
# returnStatus

# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')\nvars:\n\tmyUser: $myUser\n\tscriptVers: $scriptVers\n\tversionData: $versionData\n\tlog: $log\n\tsleepMins: $sleepMins\n\tsleepSecs: $sleepSecs\n\tinstallDir: $installDir\n\tgitJobs: $gitJobs\n\tgitBranch: $gitBranch\n\tgitCmd: $gitCmd\n\trunningDir: $runningDir\n\tidfDir: $idfDir\n\tespressifLocation: $espressifLocation\n\tcustomBinLocation: $customBinLocation\n\tcustomBinFrom: $customBinFrom\n\tinstallCmd: $installCmd\n\ttoolsInstallCmd: $toolsInstallCmd"
# returnStatus

# if ! [ -d $installDir ]; then
# 	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): creating ${installDir}"
# 	mkdir $installDir
# 	returnStatus
# fi
# 
# if [ -d $idfDir ]; then
# 	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${idfDir}"
# 	rm -rf $idfDir
# 	returnStatus
# fi
# 
# if [ -d $espressifLocation ]; then
# 	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${espressifLocation}"
# 	rm -rf "${espressifLocation}"
# 	returnStatus
# fi

# if [ -d $customBinLocation ]; then
# 	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${customBinLocation}"
# 	rm -rf $customBinLocation
# 	returnStatus
# fi
# 
# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): copying scripts from ${customBinFrom} to ${customBinLocation}"
# cp -r $customBinFrom $customBinLocation
# returnStatus
# 
# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): making scripts executable at ${customBinLocation}"
# chmod -R +x $customBinLocation
# returnStatus

# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): cloning git branch ${gitBranch} with ${gitJobs} jobs to ${idfDir}"
# eval "$gitCmd"
# returnStatus
# 
# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing with ${idfDir}/install.sh all"
# eval "$installCmd"
# returnStatus
# 
# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing tools with python ${idfDir}/tools/idf_tools.py install all"
# eval "$toolsInstallCmd"
# returnStatus

# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): backing up ${idfDir}/export.sh to ${idfDir}/export.sh.bak"
# cp $idfDir/export.sh $idfDir/export.sh.bak
# returnStatus
# 
# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): editing ${idfDir}/export.sh"
# sed -i 's/return 0/# return 0/g' $idfDir/export.sh
# returnStatus
# 
# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): adding ${runningDir}/add-to-export-sh.txt to ${idfDir}/export.sh"
# cat $runningDir/add-to-export-sh.txt >> $idfDir/export.sh
# returnStatus

# writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): getting the commit hash"
# commitHash=$(git -C $idfDir rev-parse HEAD)
# returnStatus

# gitDataLog="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installed esp-idf from commit $commitHash from branch $gitBranch using $scriptVers"
# writeToLog "$gitDataLog"
# echo -e "$gitDataLog" >> $versionData
# returnStatus

# rebootMsg="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): rebooting in $sleepMins minutes. save and log out"
# writeToLog "$rebootMsg"
# # warn_all_users "$rebootMsg"
# echo "$rebootMsg" | sudo write "$myUser"
# returnStatus

# sleepHold

#writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): force logging out all users"
# logout_all_users
# returnStatus

# endTime=$(date '+%s')
# timeElapsed=$(($endTime-$startTime))
# writeToLog "reinstall completed in $timeElapsed seconds"
# writeToLog " === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): finished ===\n\n"

# if [ "$arg" == "test" ]; then
# 	echo sudo reboot
# 
# 	rm -f $log
# 	touch $log
# 
# 	rm -f $versionData
# 	touch $versionData
# else
# 	sudo reboot
# fi