# esp-idf custom installer/reinstaller
installs/reinstalls full esp-idf with my own additions on linux.  
pulls from master so its the very latest

built for debian-like systems
only currently tested on zsh
some features require user to have passwordless sudo rights  
  
Literally the most schizophrenically overengineered thing I have ever made. idk why I did that  

## Quick start
`cd ~`
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
	each of these arguments can be used identically on the alias run_esp_reinstall
	
	default: 
		reinstalls non-interactively with no delays, logouts, or reboots. run without any argument
			bash esp-idf-tools-cmd.sh

	test:
		tests the script. very fast. minimal actions taken. no reinstall is done
			bash esp-idf-tools-cmd.sh test
			bash esp-idf-tools-cmd.sh t

	retool:
	    reinstalls bins and export.sh, nothing else
		    bash esp-idf-tools-cmd.sh retool
			bash esp-idf-tools-cmd.sh rt

	cron:
		runs noninteractively with forced user logout and automatic reboot, plus delays
		    bash esp-idf-tools-cmd.sh cron
			bash esp-idf-tools-cmd.sh c

	interactive:
		interactively installs/reinstalls esp-idf
		    bash esp-idf-tools-cmd.sh interactive
			bash esp-idf-tools-cmd.sh i

	nuke:
		full delete and re-download and install
			bash esp-idf-tools-cmd.sh nuke
			bash esp-idf-tools-cmd.sh n
    
	clearlogs:
		clear logs
			bash esp-idf-tools-cmd.sh clearlogs
			bash esp-idf-tools-cmd.sh clear
			bash esp-idf-tools-cmd.sh clean
			bash esp-idf-tools-cmd.sh cl
			
    help:
        display this help text
            bash esp-idf-tools-cmd.sh help
			bash esp-idf-tools-cmd.sh h
			bash esp-idf-tools-cmd.sh -h
			bash esp-idf-tools-cmd.sh --help

	uninstall:
		uninstall esp-idf
			bash esp-idf-tools-cmd.sh uninstall
```

## Ailases
```
run_esp_reinstall
	Updates the esp-install-custom code via git, displays the script version, then executes esp-idf-tools-cmd.sh with optional arument.
	Takes identical arguments to running esp-idf-tools-cmd.sh manually
		run_esp_reinstall
		run_esp_reinstall clean
		run_esp_reinstall nuke
		run_esp_reinstall retool
		run_esp_reinstall cron
		run_esp_reinstall interactive
		run_esp_reinstall test
		run_esp_reinstall help
		run_esp_reinstall uninstall
	Second optional argument specifies branch:
		`run_esp_reinstall nuke v5.4.1`

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
