#!/bin/bash
# set -e # for testan, die on eelrror
startTime=$(date '+%s') # to time the (re)install time for the logs

gitBranch=master # branch from github
rcFile=$HOME/.zshrc # shell rc file
gitJobs=5 # number of jobs to download from github with

if [ -z $ESPIDF_INSTALLDIR ]; then
	installDir=$HOME/esp # path to install to. $HOME/esp by default
else
	installDir=$ESPIDF_INSTALLDIR
fi

log=$installDir/install.log # log file
versionData=$installDir/version-data.txt # version data log file
idfDir=$installDir/esp-idf # esp-idf path
espressifLocation=$HOME/.espressif # espressif tools install location
customBinLocation=$installDir/.custom_bin # where custom bin scripts are placed
exportScript=$idfDir/export.sh # export script
exportBackupScript="${exportScript}.bak"
runningDir="$( cd "$( dirname "$0" )" && pwd )"
customBinFrom=$runningDir/custom_bin # dir where custom scripts are coming FROM
helpText=$runningDir/help.txt
scriptVers=$(cat $runningDir/version.txt) # make sure version.txt does NOT have newline
arg=$1 # just rename the argument var for clarity with the functions

# commands
gitCmd="git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"

installCmd="$idfDir/install.sh all"

toolsInstallCmd="$idfDir/tools/idf_tools.py install all"

# full order:
# set action string variable
# set sleepMins int variable
# redefine any other vars needed
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
	echo -e "$strii" >> $log
}

function writeToLog() {
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1"
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1" >> $log
}

function handleSleep() {
	writeToLog "Handling sleep hold (function ran)"

	sleepSecs=$(($sleepMins*60)) # calculated seconds of warning to wait for user to log out

	writeToLog "sleeping ${sleepMins} minutes"
	sleep $sleepSecs
	returnStatus
}

function handleCheckInstallPackages() {
	packages=(git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0)
	i=0
	for package in "${packages[@]}"; do
		which $package
	done
}

function handleCustomBins() {
	writeToLog "Handling custon bins (function ran)"

	if [ -d $customBinLocation ]; then
		writeToLog "deleting ${customBinLocation}"
		rm -rf $customBinLocation
		returnStatus
	else
		writeToLog "${customBinLocation} not found, skipping delete"
	fi

	writeToLog "copying scripts from ${customBinFrom} to ${customBinLocation}"
	cp -r $customBinFrom $customBinLocation
	returnStatus

	writeToLog "making scripts executable at ${customBinLocation}"
	chmod -R +x $customBinLocation
	returnStatus
}

function handleExport() {
	writeToLog "Handling $exportScript (function ran)"

	if [ -z $testExport ]; then
		writeToLog "testExport not set"

		writeToLog "backing up $exportScript to $exportBackupScript"
		cp $exportScript $exportBackupScript
		returnStatus
	else
		writeToLog "testExport enabled"

		writeToLog "deleting $exportScript"
		rm -f $exportScript
		returnStatus

		writeToLog "restoring $exportScript from backup at $exportBackupScript"
		cp $exportBackupScript $exportScript
		returnStatus
	fi

	writeToLog "adding $runningDir/add-to-export-sh.txt to $exportScript"
	cat $runningDir/add-to-export-sh.txt >> $exportScript
	returnStatus

	writeToLog "editing $exportScript to remove ending \`return 0\`"
	sed -i 's/return 0/# return 0/g' $exportScript
	returnStatus

	writeToLog "editing $exportScript with version information: $scriptVers"
	sed -i "s/versionTAG/\'$scriptVers\'/g" $exportScript
	returnStatus

	dateStampInstall=$(date '+%d-%m-%Y %H:%M:%S %Z (%s)')

	writeToLog "editing $exportScript with install date information: $dateStampInstall"
	sed -i "s/installDateTAG/\'$dateStampInstall\'/g" $exportScript
	returnStatus

	writeToLog "editing $exportScript with git commit hash data: $commitHash"
	sed -i "s/commitTAG/\'$commitHash\'/g" $exportScript
	returnStatus
}

function handleSetupEnvironment() {
	writeToLog "Handling setup environment (function ran)"

	if ! [ -d $installDir ]; then
		writeToLog "creating ${installDir}"
		mkdir $installDir
		returnStatus
	fi

	if [ -d $idfDir ]; then
		writeToLog "deleting ${idfDir}"
		rm -rf $idfDir
		returnStatus
	fi

	if [ -d $espressifLocation ]; then
		writeToLog "deleting ${espressifLocation}"
		rm -rf "${espressifLocation}"
		returnStatus
	fi
}

function handleAliasEnviron() {
	if ! [ -z $(alias | grep get_idf) ]; then
		writeToLog "get_idf alias not found, appending to ${$rcFile}"
		echo -e "\nalias get_idf='. ${exportScript}'" >> $rcFile
		returnStatus
	else
		writeToLog "get_idf alias already installed, skipping"
	fi

	if [ -z $ESPIDF_INSTALLDIR ]; then
		writeToLog "ESPIDF_INSTALLDIR environment variable not found, appending to ${rcFile}" 
		echo -e "export ESPIDF_INSTALLDIR=\"${installDir}\"\n" >> $rcFile
		returnStatus
	else
		writeToLog "ESPIDF_INSTALLDIR environment variable already installed, skipping"
	fi
}

function handleDownloadInstall() {
	writeToLog "Handling download and install (function ran)"

	writeToLog "cloning git branch $gitBranch with $gitJobs jobs to $idfDir"
	eval "$gitCmd"
	returnStatus

	# is this helpful in teh slightest? idk lel
	if [ ! -z $(which python3) ]; then
		writeToLog "python3 found at $(which python3), using"
		idfPython="python3"
	elif [! -z $(which python) ]; then
		writeToLog "python found at $(which python), using"
		idfPython="python"
	else
		writeToLog "no python found, skipping python tools install"
	fi

	writeToLog "installing with \`eval \"${idfDir}/install.sh all\"\`"
	eval "$installCmd"
	returnStatus

	if [ -z $idfPython ]; then
		writeToLog "installing tools with \`eval \"$idfPython $toolsInstallCmd\"\`"

		eval "$idfPython $toolsInstallCmd"
		returnStatus
	else
		writeToLog "No python found on system, skipping python tools install"
	fi

	writeToLog "getting the commit hash"
	commitHash=$(git -C $idfDir rev-parse HEAD)
	returnStatus

	gitDataLog="installed esp-idf from commit $commitHash from branch $gitBranch using $scriptVers"
	writeToLog "$gitDataLog"
	echo -e "$gitDataLog" >> $versionData
	returnStatus
}

handleReboot() {
	writeToLog "Handling reboot: (function ran)"

	sudo reboot
}

handleWarnAllUsers() {
	writeToLog "Warning all users of impending logout (function called)"

	warningString="\nWARNING:\n\tReinstalling esp-idf:\n\tForce logut in ${sleepMins} minutes!!\n\tSave and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall reinstall-esp-idf.sh\`"

	writeToLog "$warningString"

	handleSleep

	loggedIn=$(who | awk '{print $1}' | uniq)

	if [ -z $loggedIn ]; then
		writeToLog "no users logged in to warn"
		return
	else
		writeToLog "Warning all logged in users:" # make sure dis workan

		echo $loggedIn | while read line; do
			writeToLog "\tWarning $line"
			echo -e "$warningString" | sudo write
			returnStatus
		done
		returnStatus
	fi
}

function handleLogoutAllUsers() {
	writeToLog "Handling user logout (function ran)"

	handleWarnAllUsers

	loggedIn=$(who | awk '{print $1}' | uniq)

	if [ -z $loggedIn ]; then
		writeToLog "no logged in users to log out"
		return
	else
		writeToLog "logging out all logged in users:"
		echo $loggedIn | while read line; do
		writeToLog "\tlogging out $line"
			sudo loginctl terminate-user $line
			returnStatus
		done
		returnStatus
	fi
}

function handleCheckEspIdf() {
	if [ ! -z $IDF_PYTHON_ENV_PATH ]; then
		writeToLog "FAIL: esp-idf environment varibles found!\nPelase run from a fresh termnal that has not had get_idf ran! Exiting"
		exit
	else
		writeToLog "Santiy check: environment correct: no esp-idf evnironment variables found, proceeding"
	fi
}

function handleStart() {
	if [ -z $sleepMins ]; then 
		sleepMins="disabled"
	fi

	if [ -z $ESPIDF_INSTALLDIR ]; then
		installDirEnvvar="not set"
	else
		installDirEnvvar=$ESPIDF_INSTALLDIR
	fi

	if [ "$arg" != "interactive" -a "$arg" != "i" ]; then
		writeToLog " === NEW ${action} ==="
		writeToLog "\tVersion: ${scriptVers}\n"
	fi

	# run environment sanity check
	handleCheckEspIdf

	writeToLog "\nvars:\n\tuser: $USER\n\tscriptVers: $scriptVers\n\tversionData: $versionData\n\tlog: $log\n\tsleepMins: $sleepMins\n\tinstallDir: $installDir\n\tgitJobs: $gitJobs\n\tgitBranch: $gitBranch\n\tgitCmd: $gitCmd\n\trunningDir: $runningDir\n\tidfDir: $idfDir\n\tespressifLocation: $espressifLocation\n\tcustomBinLocation: $customBinLocation\n\tcustomBinFrom: $customBinFrom\n\tinstallCmd: $installCmd\n\ttoolsInstallCmd: $toolsInstallCmd\n\trcFile: $rcFile\n\t(envvar) ESPIDF_INSTALLDIR: $installDirEnvvar\n"
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

	echo -e "\nesp-idf re/installed! run \`source $rcFile\` and then \`get_idf\`\n to go\n\nAll done :3\n\n"

	writeToLog "reinstall completed in $timeElapsed seconds"
	writeToLog " === finished ===\n\n"
}

if [ "$arg" == "--help" -o "$arg" == "help" -o "$arg" == "-h" -o "$arg" == "h" ]; then
	cat $helpText;

	exit

elif [ "$arg" == "test" -o "$arg" == "t" ]; then # minimal actions taken, echo the given commands and such
 	action="TEST"
 
 	gitCmd="echo git clone --jobs $gitJobs --branch $gitBranch --single-branch https://github.com/espressif/esp-idf $idfDir"

 	installCmd="echo $idfDir/install.sh all"
 	
	toolsInstallCmd="echo $idfDir/tools/idf_tools.py install all"

	sleepMins=0

	testExport=1

	handleStart
	handleCheckInstallPackages
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleTestExport
	handleAliasEnviron
	handleEnd

	exit

elif [ "$arg" == "retool" -o "$arg" == "rt" ]; then # just reinstall bins and export
	action="RETOOL"

	handleStart
	handleCustomBins
	handleExport
	handleEnd

	exit

elif [ "$arg" == "interactive" -o "$arg" == "i" ]; then
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

	writeToLog "\n === new ${action} ==="
	writeToLog "\tVersion: ${scriptVers}\n"

	writeToLog "Interactive vars set:\n\tinstallDir: $installDir\n\tgitBranch: $gitBranch\n\trcFile: $rcFile\n\tgitJobs: $gitJobs"

	handleStart
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleAliasEnviron
	handleEnd

	exit

elif [ "$arg" == "cron" -o "$arg" == "c" ]; then # full install with warn, sleep, and reboot
	action="REINSTALL (CRON)"

	sleepMins=3

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

elif [ "$arg" == "clearlogs" -o "$arg" == "cl" -o "$arg" == "clear" ]; then # clear logs
	handleEmptyLogs

	exit

else # full noninteractive (re)install without logout, reboot, or sleeps
	action="REINSTALL (DEFAULT)"

	handleStart
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleAliasEnviron
	handleEnd

	exit
fi

