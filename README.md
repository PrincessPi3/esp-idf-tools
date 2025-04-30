# esp-idf Tools and Installer/Reinstaller
installs/reinstalls full esp-idf with my own additions on linux.  
pulls from master so its the very latest

built for debian-like systems
only currently tested on zsh
some features require user to have passwordless sudo rights  
  
Literally the most schizophrenically overengineered thing I have ever made. idk why I did that  

## Quick start
`git clone https://github.com/PrincessPi3/esp-idf-tools.git ~/esp-idf-tools`  
`bash ~/esp-idf-tools/esp-idf-tools-cmd.sh`  
`source ~/.zshrc`  
`get_idf`  

## Features
`build` idf.py build  
`changebaud` prompts to enter a new baud  
`changeesp` prompts to type in esp32s3, esp32c6, etc  
`changeport` opens a menu to select a serial port  
`clean` idf.py clean  
`fullclean` fully resets a project, 'idf.py fullclean' plus remove the build dir and delete some temp and backup files  
`rebuildfull` does a `fullclean` but also an `erase-flash` and also `setup`  
`setup` same as running `idf.py set-target $ESPTARGET; idf.py menuconfig; idf.py build`  
`flash` idf.py flash  
`monitor` idf.py monitor  
`erase-flash` idf.py erase-flash  
`save-defconfig` idf.py save-defconfig  
`step-flash-monitor` attempt clean, build, flash, then monitor, dying on error  
`imagesize` get binary size, broken down in various ways including total, by componant, and by file
`chipinfo` get information from the esp chip
`espinfo` get detailed information about the esp chip
`menuconfig` run `idf.py menuconfig`

## Usage
```
Modes:
	each of these arguments can be used identically on the alias run_esp_cmd
	
	default: 
		reinstalls non-interactively with no delays, logouts, or reboots. run without any argument
			run_esp_cmd

	test:
		tests the script. very fast. minimal actions taken. no reinstall is done
			run_esp_cmd test
			run_esp_cmd t

	retool:
	    reinstalls bins and export.sh, nothing else
		    run_esp_cmd retool
			run_esp_cmd rt

	cron:
		runs noninteractively with forced user logout and automatic reboot, plus delays
		    run_esp_cmd cron
			run_esp_cmd c
	update:
		runs update like cron but without logout or reboot
			run_esp_cmd update
			run_esp_cmd u

	interactive:
		interactively installs/reinstalls esp-idf
		    run_esp_cmd interactive
			run_esp_cmd i

	nuke:
		full delete and re-download and install
			run_esp_cmd nuke
			run_esp_cmd n
    
	clearlogs:
		clear logs
			run_esp_cmd clearlogs
			run_esp_cmd clear
			run_esp_cmd clean
			run_esp_cmd cl
			
    help:
        display this help text
            run_esp_cmd help
			run_esp_cmd h
			run_esp_cmd -h
			run_esp_cmd --help

	uninstall:
		run_esp_cmd uninstall
```

## Ailases
```
run_esp_cmd
	Updates the esp-install-custom code via git, displays the script version, then executes esp-idf-tools-cmd.sh with optional arument.
	Takes identical arguments to running esp-idf-tools-cmd.sh manually
		run_esp_cmd
		run_esp_cmd clean
		run_esp_cmd nuke
		run_esp_cmd retool
		run_esp_cmd cron
		run_esp_cmd update
		run_esp_cmd interactive
		run_esp_cmd test
		run_esp_cmd help
		run_esp_cmd uninstall
	Second optional argument specifies branch:
		`run_esp_cmd nuke v5.4.1`

esp_install_monitor
	monitors install.log
	alias for tail -n 75 -f $ESPIDF_INSTALLDIR/install.log
	no arguments

esp__install_logs
	displays full text of install.log and version-data.txt
	no arguments
```

## Helpful stuff
```
cron:
    reinstall from master everyday at 4am, logging out users with warn delays and rebooting after
	    `crontab -e`

	    0 4 * * * bash $HOME/esp/esp-install-custom/esp-idf-tools-cmd.sh cron
```
