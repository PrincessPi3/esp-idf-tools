#!/bin/bash
# set -e # uncomment for die on error
startTime=$(date '+%s') # to time the (re)install time for the logs

# full order:
# set action string variable
# set sleepMins int variable
# redefine any other vars needed
# handleStart
# handleClearInstallLog
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

# always run globals and boilerplate
# check for help first
if [[ "$1" == "--help" || "$1" == "help" || "$1" == "-h" || "$1" == "h" ]]; then
	helpText=$ESPIDFTOOLS_INSTALLDIR/.custom_bin/help.txt
	cat "$helpText"

	exit
fi

defShell=$(awk -F: -v user="$(whoami)" '$1 == user {print $NF}' /etc/passwd)

if [[ "$defShell" =~ zsh$ ]]; then
	echo -e "\nSelected zsh shell automatically\n"
	rcFile="$HOME/.zshrc"
elif [[ "$defShell" =~ bash$ ]]; then 
	echo -e "\nSelected bash shell automatically\n"
	rcFile="$HOME/.bashrc"
elif [[ "$defShell" =~ sh$ ]]; then
	rcFile="" # no need for rcFile var when run as cron
else
	echo "unsupported shell $defShell"
	exit
fi

rcFile="$HOME/.bashrc" # absolute path only

# get us our FUCKING ALIASES HOLY FUCK GOD DAMN SHIT FUCK IT\
source "$rcFile" 2>/dev/null # >2?/dev/null is to redirect any errors
defaultInstallDir="$HOME/esp"

if [ -z "$2" ]; then
	gitBranch=master # branch from github
else
	gitBranch="$2"
fi

if [ -z "$ESPIDFTOOLS_INSTALLDIR" ]; then
	# cant seem to get this one to use writeToLog
	echo -e "ESPIDFTOOLS_INSTALLDIR environment variable not found, appending to $rcFile\n"
	echo "export ESPIDFTOOLS_INSTALLDIR=\"$defaultInstallDir\"" >> "$rcFile"
	installDir="$defaultInstallDir"
	aliasInstallDirChk=$?
else
	echo -e "ESPIDFTOOLS_INSTALLDIR environment variable found, skipping\n"
	installDir="$ESPIDFTOOLS_INSTALLDIR"
	aliasInstallDirChk=0
fi

gitJobs=5 # number of jobs to download from github with
rebootMins=3 # minutes of warning before reboot
log="$installDir/install.log" # log file
versionData="$installDir/version-data.log" # version data log file
idfDir="$installDir/esp-idf" # esp-idf path
exportScript=$idfDir/export.sh # export script
customBinLocation="$installDir/.custom_bin" # where custom bin scripts are placed
espressifLocation="$HOME/.espressif" # espressif tools install location
runningDir="$( cd "$( dirname "$0" )" && pwd )"
customBinFrom="$runningDir/custom_bin" # dir where custom scripts are coming FROM
exportBackupScript="$runningDir/export.sh.bak" # back up to running dir
scriptVers=$(cat "$runningDir/version.txt") # make sure version.txt does NOT have newline
arg=$1 # just rename the argument var for clarity with the functions

if [ "$gitJobs" == "default" ]; then
	gitCloneCmd="git clone --single-branch --depth 1 --recursive --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
else
	gitCloneCmd="git clone --single-branch --depth 1 --recursive --jobs $gitJobs --branch $gitBranch https://github.com/espressif/esp-idf $idfDir"
fi

gitUpdateCmd="git -C $idfDir reset --hard; git -C $idfDir clean -df; git -C $idfDir pull $idfDir" # mayhapsnasst?
gitDevKits="git clone --single-branch --depth 1 --jobs $gitJobs --recursive https://github.com/espressif/esp-dev-kits.git $installDir/esp-dev-kits"
gitDevKitsUpdate="git -C $installDir/esp-dev-kits reset --hard; git -C $installDir/esp-dev-kits clean -df; git -C $installDir/esp-dev-kits pull"
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
helpExecChk=0
versionExecChk=0

function returnStatus() {
	ret=$?
	strii="\tReturn status: $ret"
	echo -e "$strii\n"
	echo -e "$strii\n" >> "$log"
	
	return $ret
}

function writeToLog() {
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1"
	echo -e "$(date '+%d/%m/%Y %H:%M:%S %Z (%s)'): $1" >> $log
}

function messagePTS() {
	if [[ ! -z $1 ]]; then
    	message="$1"
	else
    	message="Something happening! Maybe a shutdown!"
	fi
	
	for pts in $(ls -q /dev/pts); do
		if [[ "$pts" =~ ^[0-9]+$ ]] && [[ "/dev/pts/$pts" != "$(tty)" ]]; then
    		sudo echo -e "$message" > /dev/pts/$pts # requires passwordless sudo
			writeToLog "PTS Message: $message send to /dev/$pts"
		fi
	done
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
	writeToLog "Handling check and install packages (function ran)"
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
		rm -rf "$customBinLocation"
		returnStatus
		rmCustomBinChk=$?
	else
		writeToLog "$customBinLocation not found, skipping delete\n"
	fi

	writeToLog "Copying scripts from $customBinFrom to $customBinLocation"
	cp -r "$customBinFrom" "$customBinLocation"
	returnStatus
	cpCustomBinChk=$?

	writeToLog "Making scripts executable at $customBinLocation"
	chmod -R +x "$customBinLocation"
	returnStatus
	customBinExecChk=$?

	writeToLog "Copying vertson.txt and help.txt from $runningDir to $customBinLocation"
	cp "$runningDir/help.txt" "$customBinLocation"
	returnStatus
	helpExecChk=$?

	cp "$runningDir/version.txt" "$customBinLocation"
	returnStatus
	versionExecChk=$?

}

function handleExport() {
	if [ -f "$exportBackupScript" ]; then
		writeToLog "Deleting $exportBackupScript"
		rm -f "$exportBackupScript"
		returnStatus
		rmExportBackupChk=$?
	else
		writeToLog "$exportBackupScript not found, skipping delete\n"
	fi

	writeToLog "Backing up $exportScript to $exportBackupScript"
	cp "$exportScript" "$exportBackupScript"
	returnStatus
	backupExportScriptChk=$?

	writeToLog "Appending $runningDir/add-to-export-sh.txt to $exportScript"
	cat "$runningDir/add-to-export-sh.txt" >> "$exportScript"
	returnStatus
	exportCatChk=$?

	writeToLog "Editing $exportScript to remove ending \`return 0\`"
	sed -i 's/return 0/# return 0/g' "$exportScript"
	returnStatus
	exportSedReturnChk=$?

	writeToLog "Editing $exportScript with version information: $scriptVers"
	sed -i "s/versionDataTAG/\'$scriptVers\'/g" "$exportScript"
	returnStatus
	exportSedVersionChk=$?

	writeToLog "Editing $exportScript with branch information: $gitBranch"
	sed -i "s/branchDataTAG/\'$gitBranch\'/g" "$exportScript"
	returnStatus
	exportSedVersionChk=$?

	dateStampInstall=$(date '+%d-%m-%Y %H:%M:%S %Z (%s)')

	writeToLog "Editing $exportScript with install date information: $dateStampInstall"
	sed -i "s/installDateTAG/\'$dateStampInstall\'/g" "$exportScript"
	returnStatus
	exportSedDateChk=$?

	writeToLog "Editing $exportScript with git commit hash data: $commitHash"
	sed -i "s/commitTAG/\'$commitHash\'/g" "$exportScript"
	returnStatus
	exportSedHashChk=$?
}

function handleSetupEnvironment() {
	# writeToLog "Handling setup environment (function ran)\n
	if [ ! -d "$installDir" ]; then
		writeToLog "creating $installDir"
		mkdir "$installDir"
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
			rm -rf "$espressifLocation"
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
	testAppendAlias "get-esp-tools" "alias get-esp-tools='. $exportScript'"
	testAppendAlias "run-esp-cmd" "alias run-esp-cmd='bash $runningDir/esp-idf-tools-cmd.sh'"
	testAppendAlias "esp-install-monitor" "alias esp-install-monitor='tail -n 75 -f $log'"
	testAppendAlias "esp-install-logs" "alias esp-install-logs='less $versionData;less $log'"
}


function handleDownloadInstall() {
	# writeToLog "Handling download and install (function ran)\n"
	if [[ "$idfGet" == "download" || ! -d "$idfDir" ]]; then
		writeToLog "Setting for download mode\n"

		if [ -d "$idfDir" ]; then
			writeToLog "Deleting $idfDir"
			rm -rf "$idfDir"
			returnStatus
			rmIdfDirChk=$?
		else
			writeToLog "$idfDir not found, skipping delete\n"
		fi

		if [ -d "$installDir/esp-dev-kits" ]; then
			writeToLog "$installDir/esp-dev-kits found, deleting for reinstall\n"
			rm -rf "$installDir/esp-dev-kits"
			returnStatus
		else
			writeToLog "$installDir/esp-dev-kits not found, skipping delete for reinstall\n"
		fi

		istartTime=$(date '+%s')
		writeToLog "CLONING esp-idf, branch $gitBranch with $gitJobs jobs to $idfDir\n\tCommand: $gitCloneCmd"
		
		eval "$gitCloneCmd"
		returnStatus
		gitChk=$?

		writeToLog "CLONING esp-dev-kits\n\tCommand: '$gitDevKits'"
		eval "$gitDevKits"
		returnStatus
		gitChk=$?

		iendTime=$(date '+%s')
		installerTime=$(($iendTime-$istartTime))
		writeToLog "Git CLONE completed in $installerTime seconds from branch $gitBranch\n"
	else
		istartTime=$(date '+%s')
		writeToLog "Setting for update mode\n"

		writeToLog "UPDATING esp-idf, branch $gitBranch with $gitJobs jobs to $idfDir\n\tCommand: $gitUpdateCmd"
		eval "$gitUpdateCmd"
		returnStatus
		gitChk=$?

		writeToLog "UPDATING esp-dev-kits\n\tCommand: '$gitDevKitsUpdate'"
		eval "$gitDevKitsUpdate"
		returnStatus
		gitChk=$?

		iendTime=$(date '+%s')
		installerTime=$(($iendTime-$istartTime))
		writeToLog "Git UPDATE completed in $installerTime seconds from Branch $gitBranch\n"
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

	# if gitDataLog file doesnt exist, initialize with header
	if [[ ! -f "$versionData" ]]; then
		writeToLog "date&time ddmmYYYY H:M:S (unix seconds) | esp-idf branch | esp-idf-tools version | action"
		echo "date&time ddmmYYYY H:M:S (unix seconds) | esp-idf branch | esp-idf-tools version | action" > "$versionData";
	fi

	# date&time ddmmYYYY H:M:S (unix seconds) | esp-idf branch | esp-idf-tools version | action
	gitDataLog="$(date '+%d/%m/%Y %H:%M:%S %Z (%s)') | $commitHash | $gitBranch | $scriptVers | $action"
	writeToLog "$gitDataLog"
	echo "$gitDataLog" >> "$versionData"
	returnStatus
	gitLogChk=$?
}

handleReboot() {
	if [ $sleepMins -eq 0 ]; then
		messagePTS "Rebooting NOW"
		sudo reboot
	else
		messagePTS "\n\nRebooting in $sleepMins minutes\ncancel with 'shutdown -c'!!\n\n"
		sudo shutdown -r +$rebootMins
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

	if [ "$arg" != "interactive" -a "$arg" != "i" ]; then
		writeToLog " === NEW $action ==="
		writeToLog "\tVersion: $scriptVers\n"
	fi

	# run environment sanity checks
	handleCheckEspIdf
	handleCheckInstallPackages

	writeToLog "\n\tvars:\n\t\tuser: $USER\n\t\tscriptVers: $scriptVers\n\t\tversionData: $versionData\n\t\tlog: $log\n\t\tsleepMins: $sleepMins\n\t\tinstallDir: $installDir\n\t\tgitJobs: $gitJobs\n\t\tgitBranch: $gitBranch\n\t\tgitCloneCmd: $gitCloneCmd\n\t\tgitUpdateCmd: $gitUpdateCmd\n\t\t\tGitrunningDir: $runningDir\n\t\tidfDir: $idfDir\n\t\tespressifLocation: $espressifLocation\n\t\tcustomBinLocation: $customBinLocation\n\t\tcustomBinFrom: $customBinFrom\n\t\tinstallCmd: $installCmd\n\t\ttoolsInstallCmd: $toolsInstallCmd\n\t\trcFile: $rcFile\n\t\t(envvar) ESPIDFTOOLS_INSTALLDIR: $installDir\n\t\tidfGet: $idfGet\n"
}

function handleEmptyLogs() {
	echo -e "\nDeleting $log"
 	rm -f "$log"
	echo -e "\tReturn status: ${?}\n"
 
	echo "Deleting $versionData"
 	rm -f "$versionData"
	echo -e "\tReturn status: ${?}\n"
}

function handleUninstall() {
	echo -e "\nDeleting $espressifLocation"
 	rm -rf "$espressifLocation"
	echo -e "\tReturn status: ${?}\n"

	echo -e "Deleting $idfDir"
 	rm -rf "$idfDir"
	echo -e "\tReturn status: ${?}"

	handleEmptyLogs
}

function handleChk() {
	retCodes="Error Checking:\n\tPackages install: $pkgInstallChk\n\tGit pull/clone: $gitChk\n\tInstall script: $installChk\n\tInstall tools: $toolsInstallChk\n\tExport append: $exportCatChk\n\tExport edit return: $exportSedReturnChk\n\tExport version: $exportSedVersionChk\n\tExport date: $exportSedDateChk\n\tExport git hash: $exportSedHashChk\n\trun-esp-reinstall alias: $aliasRunEspReinstallChk\n\tesp-monitor alias: $aliasEspMonitorchk\n\tesp-logs alias: $aliasEspLogsChk\n\tESPIDFTOOLS_INSTALLDIR envvar: $installDir\n\tWarned Users: $warnChk\n\tLogged out users: $logoutChk\n\tAppended git log to version-data.txt: $gitLogChk\n\tAcquired git hash: $gitHashChk\n\tDeleted esp-idf dir: $rmIdfDirChk\n\tDeleted .espressif dir: $rmEspressifChk\n\tCreated install dir: $mkInstallDirChk\n\tRestored export.sh.bak: $restoreExportScriptChk\n\tDeleted old export.sh: $rmExportScriptCh\n\tBacked up export.sh to export.sh.bak: $backupExportScriptChk\n\tDeleted backup export export.bak.sh: $rmExportBackupChk\n\tMade custom scripts executable: $customBinExecChk\n\tCopied custom scripts: $cpCustomBinChk\n\tDeleted old custom scripts dir: $rmCustomBinChk\n\tWoke from sleep: $sleepChk\n\tHelp text copied: $helpExecChk\n\tversion text copied: $versionExecChk"

	totalErrorLoad=$(($pkgInstallChk+$gitChk+$gitChk+$installChk+$toolsInstallChk+$exportSedHashChk+$exportCatChk+$exportSedReturnChk+$aliasRunEspReinstallChk+$aliasEspMonitorchk+$aliasEspLogsChk+$aliasInstallDirChk+$warnChk+$logoutChk+$gitLogChk+$gitHashChk+$rmIdfDirChk+$rmEspressifChk+$mkInstallDirChk+$restoreExportScriptChk+$rmExportScriptChk+$backupExportScriptChk+$customBinExecChk+$rmCustomBinChk+$sleepChk+$rmExportBackupChk))

	if [[ $totalErrorLoad < 2 ]]; then
		writeToLog "Installed Successfully, total error load: $totalErrorLoad"
	else
		writeToLog "Install FAILED! Dumping return codes:\n"
		writeToLog "$retCodes"
	fi
}

function handleClearInstallLog() {
	if [ -f "$log" ]; then
		echo -e "\nClearing install.log\n"
		rm "$log"
	else
		echo "\n$log Not Found, Skipping Delete\n"
	fi
}

function handleEnd() {
	handleChk

	endTime=$(date '+%s')
	timeElapsed=$(($endTime-$startTime))

	echo -e "\nesp-idf (re)installed! run \`source $rcFile\` and then \`get-esp-tools\`\n\nAll done :3\n\n"

	writeToLog "Reinstall completed in $timeElapsed seconds\n"
	writeToLog " === Finished ===\n\n"
}

if [[ "$arg" == "test" || "$arg" == "t" ]]; then # minimal actions taken, echo the given commands and such
 	action="TEST"
	sleepMins=0

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
	handleEnd

	exit

elif [[ "$arg" == "interactive" || "$arg" == "install" || "$arg" == "i" ]]; then
	action="REINSTALL (INTERACTIVE)"

	echo "Enter full path to install dir, default: $installDir"
	read readInstallDir
	
	echo "Enter git branch to pull from, default: $gitBranch"
	read readGitBranch

	echo "Enter full path to rc file (/home/user/.bashrc, /home/user/.zshrc) default: $rcFile"
	read readRcFile

	echo "Enter numeber of jobs to download from github with, default: $gitJobs"
	read readgitJobs

	echo "Enter mode: update or download, deafult: download"
	read readIdfGet

	if [ ! -z $readInstallDir ]; then
		installDir="$readInstallDir"
	fi

	if [ ! -z $readGitBranch ]; then
		gitBranch="$readGitBranch"
	fi

	if [ ! -z $readRcFile ]; then
		rcFile="$readRcFile"
	fi

	if [ ! -z $readGitJobs ]; then
		gitJobs="$readGitJobs"
	fi

	if [ ! -z $readIdfGet ]; then
		idfGet="$readIdfGet"
	else
		idfGet="download"
	fi
	
	writeToLog "\n === New $action ===\n"
	writeToLog "\tVersion: $scriptVers\n"

	writeToLog "Interactive vars set:\n\tinstallDir: $installDir\n\tgitBranch: $gitBranch\n\trcFile: $rcFile\n\tgitJobs: $gitJobs\n\tidfGet: $idfGet\n"

	handleStart
	handleCheckInstallPackages
	handleSetupEnvironment
	handleAliasEnviron
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleEnd

	exit

elif [[ "$arg" == "cron" || "$arg" == "c" ]]; then # full install with warn, sleep, and reboot
	action="REINSTALL (CRON)"
	sleepMins=5
	idfGet="update"

	handleStart
	messagePTS "\n\nesp-idf-tools action $action started!\nWill reboot with $sleepMins minutes delay when complete!\n\n"
	handleClearInstallLog
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleEnd
	handleReboot

	exit

elif [[ "$arg" == "update" || "$arg" == "u" ]]; then # update without logouts or reboot
	action="UPDATE"
	idfGet="update"
	sleepMins=0

	handleStart
	handleClearInstallLog
	handleSetupEnvironment
	handleAliasEnviron
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleEnd

	exit

elif [[ "$arg" == "clearlogs" || "$arg" == "cl" || "$arg" == "clear" ]]; then
	handleEmptyLogs

	exit

elif [[ "$arg" == "nuke" || "$arg" == "n" ]]; then
	action="REINSTALL (NUKE)"
	idfGet="download"

	handleStart
	handleClearInstallLog
	handleSetupEnvironment
	handleAliasEnviron
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleEnd

	exit

elif [[ "$arg" == "nukereboot" || "$arg" == "nr" || "$arg" == "rebootnuke" || "$arg" == "rn" ]]; then
	action="REINSTALL (NUKEREBOOT)"
	sleepMins=1
	idfGet="download"

	handleStart
	messagePTS "\n\nesp-idf-tools action $action started!\nWill reboot with $sleepMins minutes delay when complete!\n\n"
	handleClearInstallLog
	handleSetupEnvironment
	handleAliasEnviron
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleEnd
	handleReboot

	exit

elif [ "$arg" == "uninstall" ]; then
	handleUninstall
	echo -e "\nAll done :3\n"

	exit

else # full noninteractive (re)install without logout, reboot, or sleeps
	action="REINSTALL (DEFAULT)"

	handleStart
	handleClearInstallLog
	handleSetupEnvironment
	handleCustomBins
	handleDownloadInstall
	handleExport
	handleAliasEnviron
	handleEnd

	exit
fi

