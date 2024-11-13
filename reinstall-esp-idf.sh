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
runningDir="$( cd "$( dirname "$0" )" && pwd )"
customBinFrom=$runningDir/custom_bin # dir where custom scripts are coming FROM
helpText=$runningDir/help.txt
exportScript=$idfDir/export.sh # export script
exportBackupScript=$runningDir/export.sh.bak # back up to running dir
scriptVers=$(cat $runningDir/version.txt) # make sure version.txt does NOT have newline
arg=$1 # just rename the argument var for clarity with the functions

# commands
gitCloneCmd="git clone --recursive --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
# gitCloneCmd="git clone --recursive --single-branch --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
gitUpdateCmd="git -C $idfDir reset --hard; git -C $idfDir clean -df; git -C $idfDir pull $idfDir" # mayhapsnasst?
installCmd="$idfDir/install.sh all"
toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"
idfGet="update" # default method

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
	ret=$?
	strii="\treturn status: $ret"
	echo -e "$strii\n"
	echo -e "$strii\n" >> $log
	
	return $ret
}

function writeToLog() {
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1"
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1" >> $log
}

function handleSleep() {
	writeToLog "Handling sleep hold (function ran)\n"

	sleepSecs=$(($sleepMins*60)) # calculated seconds of warning to wait for user to log out

	writeToLog "sleeping ${sleepMins} minutes"
	sleep $sleepSecs
	returnStatus
	sleepChk=$?
}

function handleCheckInstallPackages() {
	writeToLog "Handling check and install packages (function ran)\n"

	packages=(git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0)

	for package in "${packages[@]}"; do
		dpkg-query --show --showformat="$package \${db:Status-Status}" $package 2>/dev/null
		ret=$?

		if [ $ret -ne 0 ]; then
			echo "$package not installed, addded to list"
			installPackagees+=" $package"
		fi
	done

	if [ ! -z $installPackagees ]; then
		writeToLog "Missing packages found! Installing: $installPackagees"
		sudo apt install -y "$installPackagees"
		returnStatus
		pkgInstallChk=$?
	else
		writeToLog "No missing packages found, continuing\n"
	fi
}

function handleCustomBins() {
	writeToLog "Handling custon bins (function ran)\n"

	if [ -d $customBinLocation ]; then
		writeToLog "deleting ${customBinLocation}"
		rm -rf $customBinLocation
		returnStatus
		rmCustomBinChk=$?
	else
		writeToLog "${customBinLocation} not found, skipping delete\n"
	fi

	writeToLog "copying scripts from ${customBinFrom} to ${customBinLocation}"
	cp -r $customBinFrom $customBinLocation
	returnStatus
	cpCustomBinChk=$?

	writeToLog "making scripts executable at ${customBinLocation}"
	chmod -R +x $customBinLocation
	returnStatus
	customBinExecChk=$?
}

function handleExport() {
	writeToLog "Handling $exportScript (function ran)\n"

	if [ -z $testExport ]; then
		writeToLog "testExport not set\n"

		writeToLog "backing up $exportScript to $exportBackupScript"
		cp -f $exportScript $exportBackupScript
		returnStatus
		backupExportScriptChk=$?
	else
		writeToLog "testExport export is set\n"

		writeToLog "deleting $exportScript"
		rm -f $exportScript
		returnStatus
		rmExportScriptChk=$?

		writeToLog "restoring $exportScript from backup at $exportBackupScript"
		cp $exportBackupScript $exportScript
		returnStatus
		restoreExportScriptChk=$?
	fi

	writeToLog "adding $runningDir/add-to-export-sh.txt to $exportScript"
	cat $runningDir/add-to-export-sh.txt >> $exportScript
	returnStatus
	exportCatChk=$?

	writeToLog "editing $exportScript to remove ending \`return 0\`"
	sed -i 's/return 0/# return 0/g' $exportScript
	returnStatus
	exportSedReturnChk=$?

	writeToLog "editing $exportScript with version information: $scriptVers"
	sed -i "s/versionTAG/\'$scriptVers\'/g" $exportScript
	returnStatus
	exportSedVersionChk=$?

	dateStampInstall=$(date '+%d-%m-%Y %H:%M:%S %Z (%s)')

	writeToLog "editing $exportScript with install date information: $dateStampInstall"
	sed -i "s/installDateTAG/\'$dateStampInstall\'/g" $exportScript
	returnStatus
	exportSedDateChk=$?

	writeToLog "editing $exportScript with git commit hash data: $commitHash"
	sed -i "s/commitTAG/\'$commitHash\'/g" $exportScript
	returnStatus
	exportSedHashChk=$?
}

function handleSetupEnvironment() {
	writeToLog "Handling setup environment (function ran)\n"

	if [ ! -d "$installDir" ]; then
		writeToLog "creating $installDir"
		mkdir $installDir
		returnStatus
		mkInstallDirChk=$?
	else
		writeToLog "$installDir exisits, skiping creation\n"
	fi

	if [[ -d "$espressifLocation" && "$idfGet" == "update" ]]; then
		writeToLog "$espressifLocation set to be updated by installer\n"
		writeToLog "Skipping delete of $espressifLocation because dir exists AND idfGet is set to update\n"
	else
		writeToLog "$espressifLocation set to be reinstalled\n"

		if [ -d "$espressifLocation" ]; then
			writeToLog "$espressifLocation fonud, deleting for reinstall"
			rm -rf $espressifLocation
			returnStatus
			rmEspressifChk=$?
		else
			writeToLog "$espressifLocation not found, skipping delete for reinstall\n"
		fi
	fi
}

function handleAliasEnviron() {
#	alias get_idf 2>/dev/null
#	ret=$?
#	if [ $ret == 1 ]; then
#		writeToLog "get_idf alias not found, appending to $rcFile"
#		echo -e "\nalias get_idf='. ${exportScript}'" >> $rcFile
#		returnStatus
#	else
#		writeToLog "get_idf alias already installed, skipping\n"
#	fi
#
#	alias run_esp_reinstall 2>/dev/null
#	ret=$?
#	if [ $ret == 1 ]; then
#		writeToLog "run_esp_reinstall alias not found, appending to $rcFile"
#		echo "alias run_esp_reinstall='git -C $runningDir pull; cat $runningDir/version.txt; bash $runningDir/reinstall-esp-idf.sh '" >> $rcFile
#		returnStatus
#		aliasRunEspReinstallChk=$?
#	else
#		writeToLog "run_esp_reinstall alias already installed, skipping\n"
#		aliasRunEspReinstallChk=0
#	fi
#
#	alias esp_monitor 2>/dev/null
#	ret=$?
#	if [ $ret == 1 ]; then
#		writeToLog "esp_monitor alias not found, appending to $rcFile"
#		echo "alias esp_monitor='tail -n 75 -f $installDir/install.log'" >> $rcFile
#		returnStatus
#		aliasEspMonitorchk=$?
#	else
#		writeToLog "esp_monitor alias already installed, skipping\n"
#		aliasEspMonitorchk=0
#	fi
#
#	alias esp_logs 2>/dev/null
#	ret=$?
#	if [ $ret == 1 ]; then
#		writeToLog "esp_logs alias not found, appending to $rcFile"
#		echo "alias esp_logs='less $installDir/install.log; less $installDir/version-data.txt'" >> $rcFile
#		returnStatus
#		aliasEspLogsChk=$?
#	else
#		writeToLog "esp_logs alias already installed, skipping\n"
#		aliasEspLogsChk=0
#	fi

	if [ -z $ESPIDF_INSTALLDIR ]; then
		writeToLog "ESPIDF_INSTALLDIR environment variable not found, appending to ${rcFile}"
		echo -e "export ESPIDF_INSTALLDIR=\"${installDir}\"\n" >> $rcFile
		returnStatus
		aliasInstallDirChk=$?
	else
		writeToLog "ESPIDF_INSTALLDIR environment variable already installed, skipping\n"
		aliasInstallDirChk=0
	fi
}

function handleDownloadInstall() {
	writeToLog "Handling download and install (function ran)\n"

	if [[ "$idfGet" == "download" || ! -d "$idfDir" ]]; then
		writeToLog "Setting for download mode\n"

		if [ -d "$idfDir" ]; then
			writeToLog "deleting $idfDir"
			rm -rf $idfDir
			returnStatus
			rmIdfDirChk=$?
		else
			writeToLog "$idfDir not found, skipping delete\n"
		fi

		istartTime=$(date '+%s')
		writeToLog "CLONING esp-idf, branch $gitBranch with $gitJobs jobs to $idfDir\n\tCommand: $gitCloneCmd\n"
		eval "$gitCloneCmd"
		returnStatus
		gitChk=$?
		iendTime=$(date '+%s')
		installerTime=$(($iendTime-$istartTime))
		writeToLog "Git CLONE completed in $installerTime seconds\n"
	else
		writeToLog "Setting for update mode\n"

		istartTime=$(date '+%s')
		writeToLog "UPDATING esp-idf, branch $gitBranch with $gitJobs jobs to $idfDir\n\tCommand: $gitUpdateCmd\n"
		eval "$gitUpdateCmd"
		returnStatus
		gitChk=$?
		iendTime=$(date '+%s')
		installerTime=$(($iendTime-$istartTime))
		writeToLog "Git UPDATE completed in $installerTime seconds\n"
	fi

	istartTime=$(date '+%s')
	writeToLog "Executing installer\n\tCommand: $installCmd\n"
	eval "$installCmd"
	returnStatus
	installChk=$?
	iendTime=$(date '+%s')
	installerTime=$(($iendTime-$istartTime))
	writeToLog "Installer completed in $installerTime seconds\n"

	istartTime=$(date '+%s')
	writeToLog "Executing extra tools installer\n\tCommand: $toolsInstallCmd\n"
	eval "$toolsInstallCmd"
	returnStatus
	toolsInstallChk=$?
	iendTime=$(date '+%s')
	installerTime=$(($iendTime-$istartTime))
	writeToLog "Extra tools installer completed in $installerTime seconds\n"


	writeToLog "getting the commit hash\n"
	commitHash=$(git -C $idfDir rev-parse HEAD)
	returnStatus
	gitHashChk=$?

	gitDataLog="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)') commit $commitHash branch $gitBranch version $scriptVers action $action"
	writeToLog "$gitDataLog"
	echo "$gitDataLog" >> $versionData
	returnStatus
	gitLogChk=$?
}

handleReboot() {
	writeToLog "Handling reboot: (function ran)\n"

	sudo reboot
}

handleWarnAllUsers() {
	writeToLog "Warning all users of impending logout (function called)\n"

	warningString="\nWARNING:\n\tReinstalling esp-idf:\n\tForce logut in ${sleepMins} minutes!!\n\tSave and log out!\n\tmonitor with \`tail -f -n 50 $HOME/esp/install.log\`\n\tterminate with \`sudo killall reinstall-esp-idf.sh\`\n"

	writeToLog "$warningString"

	handleSleep

	loggedIn=$(who | awk '{print $1}' | uniq)

	if [ -z $loggedIn ]; then
		writeToLog "no users logged in to warn\n"
		return
	else
		writeToLog "Warning all logged in users:" # make sure dis workan

		echo $loggedIn | while read line; do
			writeToLog "\tWarning $line"
			echo -e "$warningString" | sudo write
			returnStatus
		done
		returnStatus
		warnChk=$?
	fi
}

function handleLogoutAllUsers() {
	writeToLog "Handling user logout (function ran)\n"

	handleWarnAllUsers

	loggedIn=$(who | awk '{print $1}' | uniq)

	if [ -z $loggedIn ]; then
		writeToLog "no logged in users to log out\n"
		return
	else
		writeToLog "logging out all logged in users:"
		echo $loggedIn | while read line; do
		writeToLog "\tlogging out $line"
			sudo loginctl terminate-user $line
			returnStatus
		done
		returnStatus
		logoutChk=$?
	fi
}

function handleCheckEspIdf() {
	if [ ! -z $IDF_PYTHON_ENV_PATH ]; then
		writeToLog "FAIL: Sanity check failed!\n\tesp-idf environment varibles found!\n\tPelase run from a fresh termnal that has not had get_idf ran!\n\tExiting\n"
		exit
	else
		writeToLog "Sanity check: Environment correct\n\tNo esp-idf environment variables found, proceeding\n"
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

	# run environment sanity checks
	handleCheckEspIdf
	handleCheckInstallPackages

	writeToLog "\n\tvars:\n\t\tuser: $USER\n\t\tscriptVers: $scriptVers\n\t\tversionData: $versionData\n\t\tlog: $log\n\t\tsleepMins: $sleepMins\n\t\tinstallDir: $installDir\n\t\tgitJobs: $gitJobs\n\t\tgitBranch: $gitBranch\n\t\tgitCloneCmd: $gitCloneCmd\n\t\tgitUpdateCmd: $gitUpdateCmd\n\t\t\tGitrunningDir: $runningDir\n\t\tidfDir: $idfDir\n\t\tespressifLocation: $espressifLocation\n\t\tcustomBinLocation: $customBinLocation\n\t\tcustomBinFrom: $customBinFrom\n\t\tinstallCmd: $installCmd\n\t\ttoolsInstallCmd: $toolsInstallCmd\n\t\trcFile: $rcFile\n\t\t(envvar) ESPIDF_INSTALLDIR: $installDirEnvvar\n\t\tidfGet: $idfGet\n"
}

function handleEmptyLogs() {
	echo -e "\n\nDeleting $log\n"
 	rm -f $log
	echo -e "\treturn status: ${?}\n"
 
	echo "Deleting $versionData"
 	rm -f $versionData
	echo -e "\treturn status: ${?}\n"

	echo "Creating empty file at $log"
 	touch $log
	echo -e "\treturn status: ${?}\n"

	echo "Creating empty file at $versionData"
 	touch $versionData
	echo -e "\treturn status: ${?}\n"
}

function handleChk() {
	retCodes="Error Checking:\n\tPackages install: $pkgInstallChk\n\tGit pull/clone: $gitChk\n\tInstall script: $installChk\n\tInstall tools: $toolsInstallChk\n\tExport append: $exportCatChk\n\tExport edit return: $exportSedReturnChk\n\tExport version: $exportSedVersionChk\n\tExport date: $exportSedDateChk\n\tExport git hash: $exportSedHashChk\n\trun_esp_reinstall alias: $aliasRunEspReinstallChk\n\tesp_monitor alias: $aliasEspMonitorchk\n\tesp_logs alias: $aliasEspLogsChk\n\tESPIDF_INSTALLDIR envvar: $aliasInstallDirChk\n\tWarned Users: $warnChk\n\tLogged out users: $logoutChk\n\tAppended git log to version-data.txt: $gitLogChk\n\tAcquired git hash: $gitHashChk\n\tDeleted esp-idf dir: $rmIdfDirChk\n\tDeleted .espressif dir: $rmEspressifChk
	\n\tCreated install dir: $mkInstallDirChk\n\tRestored export.sh.bak: $restoreExportScriptChk\n\tDeleted old export.sh: $rmExportScriptCh\n\tBacked up export.sh to export.sh.bak: $backupExportScriptChk\n\tMade custom scripts executable: $customBinExecChk\n\tCopied custom scripts: $cpCustomBinChk\n\tDeleted old custom scripts dir: $rmCustomBinChk\n\tWoke from sleep: $sleepChk"

	echo -e "\n\nTotal Error Load:\n$pkgInstallChk+$gitChk+$gitChk+$installChk+$toolsInstallChk+$exportSedHashChk+$exportCatChk+$exportSedReturnChk+$aliasRunEspReinstallChk+$aliasEspMonitorchk+$aliasEspLogsChk+$aliasInstallDirChk+$warnChk+$logoutChk+$gitLogChk+$gitHashChk+$rmIdfDirChk+$rmEspressifChk+$mkInstallDirChk+$restoreExportScriptChk+$rmExportScriptCh+$backupExportScriptChk+$customBinExecChk+$rmCustomBinChk+$sleepChk\n\n"

	# totalErrorLoad=$(($pkgInstallChk+$gitChk+$gitChk+$installChk+$toolsInstallChk+$exportSedHashChk+$exportCatChk+$exportSedReturnChk+$aliasRunEspReinstallChk+$aliasEspMonitorchk+$aliasEspLogsChk+$aliasInstallDirChk+$warnChk+$logoutChk+$gitLogChk+$gitHashChk+$rmIdfDirChk+$rmEspressifChk+$mkInstallDirChk+$restoreExportScriptChk+$rmExportScriptCh+$backupExportScriptChk+$customBinExecChk+$rmCustomBinChk+$sleepChk))

	if [[ $totalErrorLoad < 2 ]]; then
		writeToLog "Installed Successfully, total error load: $totalErrorLoad"
	else
		writeToLog "Install FAILED! Dumping return codes:\n"
		writeToLog "$retCodes"
	fi
}


function handleEnd() {
	handleChk

	endTime=$(date '+%s')
	timeElapsed=$(($endTime-$startTime))

	echo -e "\nesp-idf (re)installed! run \`source $rcFile\` and then \`get_idf\`\n\nAll done :3\n\n"

	writeToLog "reinstall completed in $timeElapsed seconds\n"
	writeToLog " === finished ===\n\n"
}

if [ "$arg" == "--help" -o "$arg" == "help" -o "$arg" == "-h" -o "$arg" == "h" ]; then
	cat $helpText;

	exit

elif [ "$arg" == "test" -o "$arg" == "t" ]; then # minimal actions taken, echo the given commands and such
 	action="TEST"
	sleepMins=0
	# testExport=1

  	installCmdTemp="echo $installCmd"
	toolsInstallCmdTemp="echo $toolsInstallCmd"
	gitCloneCmdTemp="echo $gitCloneCmd"
	updateCmdTemp="echo $gitUpdateCmd"

	installCmd=$installCmdTemp
	toolsInstallCmd=$toolsInstallCmdTemp
	gitCloneCmd=$gitcloneCmdTemp
	gitUpdateCmd=$updateCmdTemp

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
	testExport=1

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

	echo "Enter mode: update or download, deafult: update"
	read readIdfGet

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

	if [ ! -z $readIdfGet ]; then
		idfGet=$readIdfGet
	fi
	
	writeToLog "\n === new ${action} ===\n"
	writeToLog "\tVersion: ${scriptVers}\n"

	writeToLog "Interactive vars set:\n\tinstallDir: $installDir\n\tgitBranch: $gitBranch\n\trcFile: $rcFile\n\tgitJobs: $gitJobs\n\tidfGet: $idfGet\n"

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

elif [ "$arg" == "nuke" -o "$arg" == "n" ]; then # clear logs
	action="REINSTALL (NUKE)"
	idfGet="download"

	handleStart
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleAliasEnviron
	handleEnd

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

