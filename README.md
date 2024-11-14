# esp-idf custom installer/reinstaller
installs/reinstalls full esp-idf with my own additions on linux.  
pulls from master so its the very latest

built for debian-like systems
only currently tested on zsh
some features require user to have passwordless sudo rights

## Quick start
`git clone https://github.com/PrincessPi3/esp-install-custom.git ~`  
`bash ~/reinstall-esp-idf.sh`
`source ~/.zshrc`
`get_idf`

## Features
`build` idf.py build  
`changebaud` prompts to enter a new baud  
`changeesp` prompts to type in esp32s3, esp32c6, etc  
`changeport` opens a menu to select a serial port  
`clean` idf.py clean  
`fullclean` fully resets a project, 'idf.py fullclean' plus remove the build dir and delete some temp and backup files  
`menuconfig` alias of `idf.py menuconfig` b 
`rebuildfull` does a `fullclean` but also an `erase-flash` and also `setup`  
`setup` same as running `idf.py set-target $ESPTARGET; idf.py menuconfig; idf.py build`  
`flash` alias of `idf.py flash`  
`flashmonitor` alias of `idf.py flash monitor`  
`monitor` idf.py monitor  
`erase-flash` idf.py erase-flash  
`save-defconfig` idf.py save-defconfig  
`step-flash-monitor` attempt clean, build, flash, then monitor, dying on error. each ends before the next beings- found to be useful on the esp32c6  
`chipinfo` get information about the chip  
`imagesize` or gets the size of the binary to be uploaded, in genral, by componants, and by individual file

## Usage
```
Modes:
	each of these arguments can be used identically on the alias run_esp_reinstall
	
	default: 
		reinstalls non-interactively with no delays, logouts, or reboots. run without any argument
			bash reinstall-esp-idf.sh

	test:
		tests the script. very fast. minimal actions taken. no reinstall is done
			bash reinstall-esp-idf.sh test
			bash reinstall-esp-idf.sh t

	retool:
	    reinstalls bins and export.sh, nothing else
		    bash reinstall-esp-idf.sh retool
			bash reinstall-esp-idf.sh rt

	cron:
		runs noninteractively with forced user logout and automatic reboot, plus delays
		    bash reinstall-esp-idf.sh cron
			bash reinstall-esp-idf.sh c

	interactive:
		interactively installs/reinstalls esp-idf
		    bash reinstall-esp-idf.sh interactive
			bash reinstall-esp-idf.sh i

	nuke:
		full delete and re-download and install
			bash reinstall-esp-idf.sh nuke
			bash reinstall-esp-idf.sh n
    
	clearlogs:
		clear logs
			bash reinstall-esp-idf.sh clearlogs
			bash reinstall-esp-idf.sh clear
			bash reinstall-esp-idf.sh clean
			bash reinstall-esp-idf.sh cl
			
    help:
        display this help text
            bash reinstall-esp-idf.sh help
			bash reinstall-esp-idf.sh h
			bash reinstall-esp-idf.sh -h
			bash reinstall-esp-idf.sh --help

	uninstall:
		uninstall esp-idf
			bash reinstall-esp-idf.sh uninstall
```

## Ailases
```
run_esp_reinstall
	Updates the esp-install-custom code via git, displays the script version, then executes reinstall-esp-idf.sh with optional arument.
	Takes identical arguments to running reinstall-esp-idf.sh manually
		run_esp_reinstall
		run_esp_reinstall clean
		run_esp_reinstall nuke
		run_esp_reinstall retool
		run_esp_reinstall cron
		run_esp_reinstall interactive
		run_esp_reinstall test
		run_esp_reinstall help
		run_esp_reinstall uninstall

esp_monitor
	monitors install.log
	alias for tail -n 75 -f $ESPIDF_INSTALLDIR/install.log
	no arguments

esp_logs
	displays full text of install.log and version-data.txt
	no arguments
```

## Helpful stuff
```
cron:
    reinstall from master everyday at 4am, logging out users with warn delays and rebooting after
	    `crontab -e`

	    0 4 * * * bash $HOME/esp/esp-install-custom/reinstall-esp-idf.sh cron
```