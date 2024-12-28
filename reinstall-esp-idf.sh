#!/bin/bash
# set -e # for testan, die on eelrror
startTime=$(date '+%s') # to time the (re)install time for the logs

gitBranch=master # branch from github
rcFile=$HOME/.zshrc # shell rc file
# gitJobs=5 # number of jobs to download from github with
gitJobs=default # default for no --jobs x arg, integar for a number of jobs
rebootMins=3 # minutes of warning before reboot

# get us our FUCKING ALIASES HOLY FUCK GOD DAMN SHIT FUCK IT\
source $rcFile 2>/dev/null # >2?/dev/null is to redirect any errors
# echo -e "\n\nSource $rcFile\n\t retval: $?\n\n"

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
if [ "$gitJobs" == "default" ]; then
	gitCloneCmd="git clone --recursive --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
else
	gitCloneCmd="git clone --recursive --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
fi

# gitCloneCmd="git clone --recursive --single-branch --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"

gitUpdateCmd="git -C $idfDir reset --hard; git -C $idfDir clean -df; git -C $idfDir pull $idfDir" # mayhapsnasst?

installCmd="$idfDir/install.sh all"

toolsInstallCmd="python $idfDir/tools/idf_tools.py install all"

idfGet="update" # default method

# default values for retcodes
exportCatChk=0
pkgInstallChk=0
gitChk=0
installChk=0
toolsInstallChk=0
exportSedReturnChk=0
exportSedVersionChk=0
exportSedDateChk=0
exportSedHashChk=0
aliasRunEspReinstallChk=0
aliasEspMonitorchk=0
aliasEspLogsChk=0
aliasInstallDirChk=0
warnChk=0
logoutChk=0
gitLogChk=0
gitHashChk=0
rmIdfDirChk=0
rmEspressifChk=0
mkInstallDirChk=0
restoreExportScriptChk=0
rmExportScriptChk=0
backupExportScriptChk=0
customBinExecChk=0
cpCustomBinChk=0
rmCustomBinChk=0
sleepChk=0
rmExportBackupChk=0

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
	strii="\tReturn status: $ret"
	echo -e "$strii\n"
	echo -e "$strii\n" >> $log
	
	return $ret
}

function writeToLog() {
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1"
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1" >> $log
}

# this is not needed so long as warn doesnt god damned fucking work lmfao
function handleSleep() {
	# writeToLog "Handling sleep hold (function ran)\n"
	sleepSecs=$(($sleepMins*60)) # calculated seconds of warning to wait for user to log out

	writeToLog "Sleeping $sleepMins minutes"
	sleep $sleepSecs
	returnStatus
	sleepChk=$?
}

function handleCheckInstallPackages() {
	# writeToLog "Handling check and install packages (function ran)\n"
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
	# writeToLog "Handling custon bins (function ran)\n"
	if [ -d $customBinLocation ]; then
		writeToLog "Deleting $customBinLocation"
		rm -rf $customBinLocation
		returnStatus
		rmCustomBinChk=$?
	else
		writeToLog "$customBinLocation not found, skipping delete\n"
	fi

	writeToLog "Copying scripts from $customBinFrom to $customBinLocation"
	cp -r $customBinFrom $customBinLocation
	returnStatus
	cpCustomBinChk=$?

	writeToLog "Making scripts executable at $customBinLocation"
	chmod -R +x $customBinLocation
	returnStatus
	customBinExecChk=$?
}

function handleExport() {
	if [ -f $exportBackupScript ]; then
		writeToLog "Deleting $exportBackupScript"
		rm -f $exportBackupScript
		returnStatus
		rmExportBackupChk=$?
	else
		writeToLog "$exportBackupScript not found, skipping delete\n"
	fi

	writeToLog "Backing up $exportScript to $exportBackupScript"
	cp $exportScript $exportBackupScript
	returnStatus
	backupExportScriptChk=$?

	writeToLog "Appending $runningDir/add-to-export-sh.txt to $exportScript"
	cat $runningDir/add-to-export-sh.txt >> $exportScript
	returnStatus
	exportCatChk=$?

	writeToLog "Editing $exportScript to remove ending \`return 0\`"
	sed -i 's/return 0/# return 0/g' $exportScript
	returnStatus
	exportSedReturnChk=$?

	writeToLog "Editing $exportScript with version information: $scriptVers"
	sed -i "s/versionTAG/\'$scriptVers\'/g" $exportScript
	returnStatus
	exportSedVersionChk=$?

	dateStampInstall=$(date '+%d-%m-%Y %H:%M:%S %Z (%s)')

	writeToLog "Editing $exportScript with install date information: $dateStampInstall"
	sed -i "s/installDateTAG/\'$dateStampInstall\'/g" $exportScript
	returnStatus
	exportSedDateChk=$?

	writeToLog "Editing $exportScript with git commit hash data: $commitHash"
	sed -i "s/commitTAG/\'$commitHash\'/g" $exportScript
	returnStatus
	exportSedHashChk=$?
}

function handleSetupEnvironment() {
	# writeToLog "Handling setup environment (function ran)\n"
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
			writeToLog "$espressifLocation found, deleting for reinstall"
			rm -rf $espressifLocation
			returnStatus
			rmEspressifChk=$?
		else
			writeToLog "$espressifLocation not found, skipping delete for reinstall\n"
		fi
	fi
}

function testAppendAlias() {
	echo "Testing alias '$1'"
	alias $1 2>/dev/null # redirect errrors to keep it lookan clean
	ret=$?
	if [ ! $ret -eq 0 ]; then
		writeToLog "$1 not found, appending to $rcFile"
		echo "$2" >> "$rcFile"
		returnStatus
	else
		writeToLog "$1 found: $(alias $1), skipping\n"
	fi

	return $ret	
}

function handleAliasEnviron() {
	testAppendAlias "get_idf" "alias get_idf='. $exportScript'"
	testAppendAlias "run_esp_reinstall" "alias run_esp_reinstall='git -C $runningDir pull;echo -e \"\nOld Version:\";tail -1 $versionData;echo -e \"\n\";bash $runningDir/reinstall-esp-idf.sh n'"
	testAppendAlias "esp_install_monitor" "alias esp_monitor='tail -n 75 -f $log'"
	testAppendAlias "esp_install_logs" "alias esp_logs='less $versionData;less $log'"

	if [ -z $ESPIDF_INSTALLDIR ]; then
		writeToLog "ESPIDF_INSTALLDIR environment variable not found, appending to $rcFile"
		echo -e "export ESPIDF_INSTALLDIR=\"$installDir\"\n" >> $rcFile
		returnStatus
		aliasInstallDirChk=$?
	else
		writeToLog "ESPIDF_INSTALLDIR environment variable already installed, skipping\n"
		aliasInstallDirChk=0
	fi
}

function handleDownloadInstall() {
	# writeToLog "Handling download and install (function ran)\n"
	if [[ "$idfGet" == "download" || ! -d "$idfDir" ]]; then
		writeToLog "Setting for download mode\n"

		if [ -d "$idfDir" ]; then
			writeToLog "Deleting $idfDir"
			rm -rf $idfDir
			returnStatus
			rmIdfDirChk=$?
		else
			writeToLog "$idfDir not found, skipping delete\n"
		fi

		istartTime=$(date '+%s')
		writeToLog "CLONING esp-idf, branch $gitBranch with $gitJobs jobs to $idfDir\n\tCommand: $gitCloneCmd"
		eval "$gitCloneCmd"
		returnStatus
		gitChk=$?
		iendTime=$(date '+%s')
		installerTime=$(($iendTime-$istartTime))
		writeToLog "Git CLONE completed in $installerTime seconds\n"
	else
		writeToLog "Setting for update mode\n"

		istartTime=$(date '+%s')
		writeToLog "UPDATING esp-idf, branch $gitBranch with $gitJobs jobs to $idfDir\n\tCommand: $gitUpdateCmd"
		eval "$gitUpdateCmd"
		returnStatus
		gitChk=$?
		iendTime=$(date '+%s')
		installerTime=$(($iendTime-$istartTime))
		writeToLog "Git UPDATE completed in $installerTime seconds\n"
	fi

	istartTime=$(date '+%s')
	writeToLog "Executing installer\n\tCommand: $installCmd"
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


	writeToLog "Getting the commit hash"
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
	# writeToLog "Handling reboot: (function ran)\n"
	eval "sudo shutdown -r +$rebootMins"
}

# warning not work how i make it work fuckin ell
handleWarnAllUsers() {
	# writeToLog "Warning all users of impending logout (function called)\n"
	warningString="\nWARNING:\n\tReinstalling esp-idf:\n\tForce logut in $sleepMins minutes!!\n\tSave and log out!\n\tmonitor with \`esp+monitor\`\n\tterminate with \`sudo killall reinstall-esp-idf.sh\`\n"

	writeToLog "$warningString"


	loggedIn=$(who | awk '{print $1}' | uniq)

	if [ -z $loggedIn ]; then
		writeToLog "No users logged in to warn\n"
		return
	else
		writeToLog "Skipping warning all logged in users: $loggedIn\n"
	fi
		# writeToLog "Warning all logged in users: $loggedIn"
		# sudo wall --nobanner "$warningString"
		# returnStatus
		# warnChk=$?
		#
		# handleSleep

}

# dis one sure af be workan tho lmfao
function handleLogoutAllUsers() {
	# writeToLog "Handling user logout (function ran)\n"
	handleWarnAllUsers

	loggedIn=$(who | awk '{print $1}' | uniq)

	if [ -z $loggedIn ]; then
		writeToLog "No logged in users to log out\n"
		return
	else
		writeToLog "Logging out all logged in users: $loggedIn"
		echo $loggedIn | while read line; do
		writeToLog "\tLogging out $line"
			sudo loginctl terminate-user $line
			returnStatus
		done
		returnStatus
		logoutChk=$?
	fi
}

function handleCheckEspIdf() {
	if [ ! -z $IDF_PYTHON_ENV_PATH ]; then
		writeToLog "FAIL: Sanity check failed!\n\tesp-idf environment varibles found!\n\tPelase run from a fresh termnal that has not had get_idf ran!\n"
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
		writeToLog " === NEW $action ==="
		writeToLog "\tVersion: $scriptVers\n"
	fi

	# run environment sanity checks
	handleCheckEspIdf
	handleCheckInstallPackages

	writeToLog "\n\tvars:\n\t\tuser: $USER\n\t\tscriptVers: $scriptVers\n\t\tversionData: $versionData\n\t\tlog: $log\n\t\tsleepMins: $sleepMins\n\t\tinstallDir: $installDir\n\t\tgitJobs: $gitJobs\n\t\tgitBranch: $gitBranch\n\t\tgitCloneCmd: $gitCloneCmd\n\t\tgitUpdateCmd: $gitUpdateCmd\n\t\t\tGitrunningDir: $runningDir\n\t\tidfDir: $idfDir\n\t\tespressifLocation: $espressifLocation\n\t\tcustomBinLocation: $customBinLocation\n\t\tcustomBinFrom: $customBinFrom\n\t\tinstallCmd: $installCmd\n\t\ttoolsInstallCmd: $toolsInstallCmd\n\t\trcFile: $rcFile\n\t\t(envvar) ESPIDF_INSTALLDIR: $installDirEnvvar\n\t\tidfGet: $idfGet\n"
}

function handleEmptyLogs() {
	echo -e "\nDeleting $log"
 	rm -f $log
	echo -e "\tReturn status: ${?}\n"
 
	echo "Deleting $versionData"
 	rm -f $versionData
	echo -e "\tReturn status: ${?}\n"

	echo "Creating empty file at $log"
 	touch $log
	echo -e "\tReturn status: ${?}\n"

	echo "Creating empty file at $versionData"
 	touch $versionData
	echo -e "\tReturn status: ${?}\n"
}

function handleUninstall() {
	echo -e "\nDeleting $espressifLocation"
 	rm -rf $espressifLocation
	echo -e "\tReturn status: ${?}\n"

	echo -e "Deleting $idfDir"
 	rm -rf $idfDir
	echo -e "\tReturn status: ${?}"

	handleEmptyLogs
}

function handleChk() {
	retCodes="Error Checking:\n\tPackages install: $pkgInstallChk\n\tGit pull/clone: $gitChk\n\tInstall script: $installChk\n\tInstall tools: $toolsInstallChk\n\tExport append: $exportCatChk\n\tExport edit return: $exportSedReturnChk\n\tExport version: $exportSedVersionChk\n\tExport date: $exportSedDateChk\n\tExport git hash: $exportSedHashChk\n\trun_esp_reinstall alias: $aliasRunEspReinstallChk\n\tesp_monitor alias: $aliasEspMonitorchk\n\tesp_logs alias: $aliasEspLogsChk\n\tESPIDF_INSTALLDIR envvar: $aliasInstallDirChk\n\tWarned Users: $warnChk\n\tLogged out users: $logoutChk\n\tAppended git log to version-data.txt: $gitLogChk\n\tAcquired git hash: $gitHashChk\n\tDeleted esp-idf dir: $rmIdfDirChk\n\tDeleted .espressif dir: $rmEspressifChk\n\tCreated install dir: $mkInstallDirChk\n\tRestored export.sh.bak: $restoreExportScriptChk\n\tDeleted old export.sh: $rmExportScriptCh\n\tBacked up export.sh to export.sh.bak: $backupExportScriptChk\n\tDeleted backup export export.bak.sh: $rmExportBackupChk\n\tMade custom scripts executable: $customBinExecChk\n\tCopied custom scripts: $cpCustomBinChk\n\tDeleted old custom scripts dir: $rmCustomBinChk\n\tWoke from sleep: $sleepChk"

	totalErrorLoad=$(($pkgInstallChk+$gitChk+$gitChk+$installChk+$toolsInstallChk+$exportSedHashChk+$exportCatChk+$exportSedReturnChk+$aliasRunEspReinstallChk+$aliasEspMonitorchk+$aliasEspLogsChk+$aliasInstallDirChk+$warnChk+$logoutChk+$gitLogChk+$gitHashChk+$rmIdfDirChk+$rmEspressifChk+$mkInstallDirChk+$restoreExportScriptChk+$rmExportScriptChk+$backupExportScriptChk+$customBinExecChk+$rmCustomBinChk+$sleepChk+$rmExportBackupChk))

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

	writeToLog "Reinstall completed in $timeElapsed seconds\n"
	writeToLog " === Finished ===\n\n"
}

if [[ "$arg" == "--help" || "$arg" == "help" || "$arg" == "-h" || "$arg" == "h" ]]; then
	cat $helpText;

	exit

elif [[ "$arg" == "test" || "$arg" == "t" ]]; then # minimal actions taken, echo the given commands and such
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

elif [[ "$arg" == "retool" || "$arg" == "rt" ]]; then # just reinstall bins and export
	action="RETOOL"
	testExport=1

	handleStart
	handleCustomBins
	handleExport
	handleEnd

	exit

elif [[ "$arg" == "interactive" || "$arg" == "i" ]]; then
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
	
	writeToLog "\n === New $action ===\n"
	writeToLog "\tVersion: $scriptVers\n"

	writeToLog "Interactive vars set:\n\tinstallDir: $installDir\n\tgitBranch: $gitBranch\n\trcFile: $rcFile\n\tgitJobs: $gitJobs\n\tidfGet: $idfGet\n"

	handleStart
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleAliasEnviron
	handleEnd

	exit

elif [[ "$arg" == "cron" || "$arg" == "c" ]]; then # full install with warn, sleep, and reboot
	action="REINSTALL (CRON)"
	# sleepMins=3
	sleepMins=0

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

elif [[ "$arg" == "clearlogs" || "$arg" == "cl" || "$arg" == "clear" || "$arg" == "clean" ]]; then # clear logs
	handleEmptyLogs

	exit

elif [[ "$arg" == "nuke" || "$arg" == "n" ]]; then # clear logs
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

elif [ "$arg" == "uninstall" ]; then # clear logs
	handleUninstall
	echo -e "\nAll done :3\n"
	exit

elif [ ! -z $arg ]; then 
	 writeToLog "FAIL: bad argument. Terminating"
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

