#!/bin/bash
# set -e # for testan, die on eelrror
startTime=$(date '+%s') # to time the (re)install time for the logs

gitBranch=master # branch from github
rcFile=$HOME/.zshrc # shell rc file
gitJobs=5 # number of jobs to download from github with

if [ -z $ESPIDF_INSTALLDIR ]; then
	installDir=$HOME/esp
else
	installDir=$ESPIDF_INSTALLDIR
fi

log=$installDir/install.log # log file
versionData=$installDir/version-data.txt # version data log file
idfDir=$installDir/esp-idf # esp-idf path
espressifLocation=$HOME/.espressif # espressif tools install location
customBinLocation=$installDir/.custom_bin # where custom bin scripts are placed
runningDir="$( cd "$( dirname "$0" )" && pwd )"
customBinFrom=$runningDir/custom_bin # dir where custom scripts are coming FROM
helpText=$runningDir/help.txt
scriptVers=$(cat $runningDir/version.txt) # make sure version.txt does NOT have newline
arg=$1 # just rename the argument var for clarity with the functions

# full order:
# handleStart
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

function returnStatus() {
	strii="\treturn status: ${?}"
	echo -e "$strii\n"
	echo -e "$strii\n" >> $log
}

function writeToLog() {
	echo -e "$1"
	echo -e "$1" >> $log
}

function handleSleep() {
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
	cp $idfDir/export.sh $idfDir/export.sh.bakno
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

	sudo reboot
}

# function handleWarn() {
# 	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling warn (function ran)"
#  
# 	warningString="WARNING:\n\tReinstalling esp-idf:\n\tForce logut in ${sleepMins} minutes!!\n\tSave and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall reinstall-esp-idf.sh\`\n\t$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')"
# 	writeToLog $warningString
# 
# 	sleepHold
# 
# 	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Force logging out all users"
# 
# 	echo -e "$warningString" | sudo write "$myUser"
# 	returnStatus
# }

handleWarnAllUsers() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Warning all users of impending logout (function called)"

	warningString="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'):\nWARNING:\n\tReinstalling esp-idf:\n\tForce logut in ${sleepMins} minutes!!\n\tSave and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall reinstall-esp-idf.sh\`"

	writeToLog "$warningString"

	handleSleep

	loggedIn=$(who | awk '{print $1}' | uniq)

	echo $loggedIn | while read line; do
		echo -e "$warningString" | sudo write
	done
	returnStatus
}

function handleLogoutAllUsers() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Handling user logout (function ran)"

	handleWarnAllUsers

	loggedIn=$(who | awk '{print $1}' | uniq)

	echo $loggedIn | while read line; do
		sudo loginctl terminate-user $line
	done
	returnStatus
}

function handleStart() {
	if [ -z $sleepMins ]; then 
		sleepMins="disabled"
	fi

	if [ -z $ESPIDF_INSTALLDIR ]; then
		installdirEnvvar="not set"
	else
		installdirEnvvar=$ESPIDF_INSTALLDIR
	fi

	writeToLog "\n === $(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): new ${action} ==="
	writeToLog "\tVersion: ${scriptVers}\n"

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)')\nvars:\n\tuser: $USER\n\tscriptVers: $scriptVers\n\tversionData: $versionData\n\tlog: $log\n\tsleepMins: $sleepMins\n\tinstallDir: $installDir\n\tgitJobs: $gitJobs\n\tgitBranch: $gitBranch\n\tgitCmd: $gitCmd\n\trunningDir: $runningDir\n\tidfDir: $idfDir\n\tespressifLocation: $espressifLocation\n\tcustomBinLocation: $customBinLocation\n\tcustomBinFrom: $customBinFrom\n\tinstallCmd: $installCmd\n\ttoolsInstallCmd: $toolsInstallCmd\n\trcFile: $rcFile\n\t(envvar) ESPIDF_INSTALLDIR: $installdirEnvvar"

}

function handleEmptyLogs() {
	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Emptying and touching logs (function ran)"

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

if [ "$arg" == "--help" -o "$arg" == "help" -o "$arg" == "-h" -o "$arg" == "h" ]; then
	cat $helpText;

	exit

elif [ "$arg" == "test" ]; then # minimal actions taken, echo the given commands and such
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
	# handleEmptyLogs
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

	echo "Enter full path to install dir, default: $installDir"
	read readInstallDir
	
	echo "Enter git branch to pull from, default: $gitBranch"
	read readGitBranch
	
	echo "Enter full path to rc file (.bashrc, .zshrc) default: $rcFile"
	read readRcFile

	echo "Enter numeber of jobs to download from github with, default: $gitJobs"
	read readgitJobs

	if [ ! -z $readInstallDir ]; then
		installDir=$readInstallDir
	fi

	if [ ! -z $readGitBranch ]; then
		gitBranch=$readGitBranch
	fi

	if [ ! -z $readRcFile ]; then
		rcFile=$readRcFile
	fi

	if [ ! -z $readGitJobs ]; then
		gitJobs=$readGitJobs
	fi

	writeToLog "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): Interactive vars set:\n\tinstallDir: $installDir\n\tgitBranch: $gitBranch\n\trcFile: $rcFile\n\tgitJobs: $gitJobs"

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

elif [ "$arg" == "cron" ]; then # full install with warn, sleep, and reboot
	action="REINSTALL (CRON)"
	
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

else # full noninteractive (re)install without logout, reboot, or sleeps
	action="REINSTALL (DEFAULT)"
	
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
fi

