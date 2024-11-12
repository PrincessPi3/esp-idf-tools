#!/bin/bash
# set -e # for testan, die on error
startTime=$(date '+%s')

# testing:


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
rcFile=${HOME}/.zshrc
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
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling sleep hold (function ran)"

	sleepSecs=$(($sleepMins*60)) # calculated seconds of warning to wait for user to log out

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): sleeping ${sleepMins} minutes"
	sleep $sleepSecs
	returnStatus
}

function handleCustomBins() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling custon bins (function ran)"

	if [ -d $customBinLocation ]; then
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): deleting ${customBinLocation}"
		rm -rf $customBinLocation
		returnStatus
	else
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): ${customBinLocation} not found, skipping delete"
	fi

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): copying scripts from ${customBinFrom} to ${customBinLocation}"
	cp -r $customBinFrom $customBinLocation
	returnStatus

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): making scripts executable at ${customBinLocation}"
	chmod -R +x $customBinLocation
	returnStatus
}

function handleExport() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling export.sh (function ran)"

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
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling setup environment (function ran)"

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

function handleAliasEnviron() {
	if ! [ -z $(alias | grep get_idf) ]; then
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): get_idf alias not found, appending to ${$rcFile}"
		echo -e "\nalias get_idf='. ${idfDir}/export.sh'" >> $rcFile
		returnStatus
	else
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): get_idf alias already installed, skipping"
	fi

	if [ -z $ESPIDF_INSTALLDIR ]; then
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): ESPIDF_INSTALLDIR environment variable not found, appending to ${rcFile}" 
		echo -e "export ESPIDF_INSTALLDIR=\"${installDir}\"\n" >> $rcFile
		returnStatus
	else
		writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): ESPIDF_INSTALLDIR environment variable already installed, skipping"
	fi
}

function handleDownloadInstall() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling download and install (function ran)"

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): cloning git branch ${gitBranch} with ${gitJobs} jobs to ${idfDir}"
	eval "$gitCmd"
	returnStatus

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing with ${idfDir}/install.sh all"
	eval "$installCmd"
	returnStatus

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installing tools with python ${idfDir}/tools/idf_tools.py install all"
	eval "$toolsInstallCmd"
	returnStatus

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): getting the commit hash"
	commitHash=$(git -C $idfDir rev-parse HEAD)
	returnStatus

	gitDataLog="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): installed esp-idf from commit $commitHash from branch $gitBranch using $scriptVers"
	writeToLog "$gitDataLog"
	echo -e "$gitDataLog" >> $versionData
	returnStatus
}

handleReboot() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)') Handling reboot: (function ran)"

	rebootMsg="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): rebooting in $sleepMins minutes. save and log out"
	writeToLog "$rebootMsg"

	echo "$rebootMsg" | sudo write "$myUser"
	returnStatus
}

function handleWarn() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling warn (function ran)"
 
	warningString="WARNING:\n\tReinstalling esp-idf in ${sleepMins} minutes! You will be force logged out in ${sleepMins} minutes! Save and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall cron-reinstall-esp-idf.sh\`\n\t$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')"
	writeToLog $warningString

	sleepHold

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Force logging out ${myUser}"

	echo -e "$warningString" | sudo write "$myUser"
	returnStatus
}

function handleLogoutAllUsers() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling user logout (function ran)"

	handleWarn

	# logout all users
	who | sudo awk '$1 !~ /root/{ cmd="/usr/bin/loginctl terminate-user " $1; system(cmd)}'
	returnStatus
}

function handleStart() {
	if [ -z $sleepMins ]; then 
		sleepMins="disabled"
	fi

	writeToLog "\n === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): new ${action} ==="
	writeToLog "Version: ${scriptVers}"

	returnStatus
	writeToLog "\n$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')\nvars:\n\tmyUser: $myUser\n\tscriptVers: $scriptVers\n\tversionData: $versionData\n\tlog: $log\n\tsleepMins: $sleepMins\n\tinstallDir: $installDir\n\tgitJobs: $gitJobs\n\tgitBranch: $gitBranch\n\tgitCmd: $gitCmd\n\trunningDir: $runningDir\n\tidfDir: $idfDir\n\tespressifLocation: $espressifLocation\n\tcustomBinLocation: $customBinLocation\n\tcustomBinFrom: $customBinFrom\n\tinstallCmd: $installCmd\n\ttoolsInstallCmd: $toolsInstallCmd\n\trcFile: $rcFile"

}

function handleEmptyLogs() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Emptying logs (function ran)"

 	rm -f $log
 	touch $log
 
 	rm -f $versionData
 	touch $versionData
}

function handleEnd() {
	endTime=$(date '+%s')
	timeElapsed=$(($endTime-$startTime))

	echo -e "\nesp-idf re/installed! run \`source $rcFile\` and then \`get_idf\`\n to go\n\nAll done :3\n\n"

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
# handleAliasEnviron
# handleLogoutAllUsers
# handleEnd
# handleReboot
# exit


if [ "$arg" == "test" ]; then # minimal actions taken, echo the given commands and such
 	action="TEST"
 
 	gitCmd="echo git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"

 	installCmd="echo $idfDir/install.sh all"
 	
	toolsInstallCmd="echo python $idfDir/tools/idf_tools.py install all"

	sleepMins=0

	handleStart
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleAliasEnviron
	handleEmptyLogs
	handleEnd
	exit

elif [ "$arg" == "nologout" ]; then # full reinstall without logout, reboot, or sleeps
	action="REINSTALL (NOLOGOUT)"
	
 	gitCmd="git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"

 	installCmd="$idfDir/install.sh all"
 	
	toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"

	handleStart
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleAliasEnviron
	handleEnd
	exit

elif [ "$arg" == "retool" ]; then # just reinstall bins and export
	action="RETOOL"

	handleStart
	handleCustomBins
	handleExport
	handleEnd
	exit

elif [ "$arg" == "interactive" ]; then
	action="REINSTALL (INTERACTIVE)"
	# something here lmfao
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