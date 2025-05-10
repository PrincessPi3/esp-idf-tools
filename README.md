# esp-idf Tools and Installer/Reinstaller
installs/reinstalls full esp-idf with my own additions on linux.  
pulls from master so its the very latest

built for debian-like systems
only currently tested on zsh
some features require user to have passwordless sudo rights  
  
Literally the most schizophrenically overengineered thing I have ever made. idk why I did that  

## Quick start
1. `git clone https://github.com/PrincessPi3/esp-idf-tools.git ~/esp-idf-tools`  
2. `bash ~/esp-idf-tools/esp-idf-tools-cmd.sh install`  
3. `source ~/.zshrc`
4. `get-esp-tools`  

## Usage
```
Some take optional [branch] paramater  
[branch] is the esp-idf branch you desire, defaults to master if not specified.
	run-esp-cmd
		reinstalls non-interactively with no delays, logouts, or reboots
			`run-esp-cmd`

	run-esp-cmd test
		tests the script. very fast. minimal actions taken. no reinstall is done
			`run-esp-cmd test [branch]`
			`run-esp-cmd t [branch]`

	run-esp-cmd retool
	    reinstalls bins and export.sh, nothing else
		    `run-esp-cmd retool`
			`run-esp-cmd rt`

	run-esp-cmd cron
		runs noninteractively with forced user logout and automatic reboot, plus delays
		    `run-esp-cmd cron [branch]`
			`run-esp-cmd c [branch]`

	run-esp-cmd update
		updates and installs latest without reboot or user logout
			`run-esp-cmd update [branch]`
			`run-esp-cmd u [branch]`

	run-esp-cmd interactive
		interactively installs/reinstalls esp-idf
		    `run-esp-cmd interactive`
			`run-esp-cmd i`
			`run-esp-cmd install`

	run-esp-cmd nuke
		full delete and re-download and install
			`run-esp-cmd nuke [branch]`
			`run-esp-cmd n [branch]`
	
	run-esp-cmd nukereboot
		full delete and re-download and install, then reboot
			`run-esp-cmd nukereboot [branch]`
			`run-esp-cmd nr [branch]`

	run-esp-cmd clearlogs
		clear logs
			`run-esp-cmd clearlogs`
			`run-esp-cmd clear`
			`run-esp-cmd cl`

	run-esp-cmd help
		display this help text
            `run-esp-cmd help`
			`run-esp-cmd h`
			`run-esp-cmd -h`
			`run-esp-cmd --help`
			`help-esp-tools`

	run-esp-cmd uninstall
		uninstall esp-idf
			`run-esp-cmd uninstall`
```

## Features
* `get-idf-tools` enter esp-idf
* `help-esp-tools` show this help
* `exit-esp-tools` exit esp-idf and reset terminal
* `build` idf.py build  
* `changebaud` alone prompts to enter baudrate
	* `changebaud <baudrate>` sets baudrate manually
		* ex. `changebaud 115200`
* `changeesp` change esp device
	* `changeesp` alone prompts to enter
		* `changeesp <esp device>` manually changes to <esp device>
		* ex. `changeesp esp32p4`
* `changeport` change serial port
	* `changeport` alone prompts to select
	* `changeport <tty device path>` manually specifies path
		* ex. `changeport /dev/ttyUSB0` changes to /dev/ttyUSB0
* `clean` idf.py clean  
* `fullclean` fully resets a project, 'idf.py fullclean' plus remove the build dir and delete some temp and backup files  
* `rebuildfull` does a `fullclean` but also an `erase-flash` and also `setup`  
* `setup` same as running `idf.py set-target $ESPTARGET; idf.py menuconfig; idf.py build`  
* `flash` idf.py flash  
* `monitor` idf.py monitor  
* `erase-flash` idf.py erase-flash  
* `save-defconfig` idf.py save-defconfig  
* `step-flash-monitor` attempt clean, build, flash, then monitor, dying on error  
* `imagesize` get binary size, broken down in various ways including total, by componant, and by file
* `chipinfo` get information from the esp chip
* `espinfo` get detailed information from the esp chip
* `menuconfig` run `idf.py menuconfig`
* `create-project` alone prompts for a project name
	* `create-project <project name>` creates a project with <project name>
		* ex. `create-project hello-world`
* `esp-install-monitor` monitors install.log. alias for `tail -n 75 -f $ESPIDFTOOLS_INSTALLDIR/install.log`
* `esp-install-logs` displays full text of install.log and version-data.txt
* `$examples` is a shortcut for examples directory in esp-idf
	* ex. cd `$examples`

### Cronjob
reinstall from master everyday at 4am, logging out users with warn delays and rebooting after
* `crontab -e`
add below to bottom of file:
* `0 4 * * * bash $HOME/esp/esp-install-custom/esp-idf-tools-cmd.sh cron`