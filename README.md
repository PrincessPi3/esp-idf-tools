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
`rebuildfull` does a `fullclean` but also an `erase-flash` and also `setup`  
`setup` same as running `idf.py set-target $ESPTARGET; idf.py menuconfig; idf.py build`  
`flash` idf.py flash  
`monitor` idf.py monitor  
`erase-flash` idf.py erase-flash  
`save-defconfig` idf.py save-defconfig  
`step-flash-monitor` attempt clean, build, flash, then monitor, dying on error  

## Usage
```
Modes:
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
    
	clearlogs:
		clear logs
			bash reinstall-esp-idf.sh clearlogs
			bash reinstall-esp-idf.sh clear
			bash reinstall-esp-idf.sh cl
			
    help:
        display this help text
            bash reinstall-esp-idf.sh help
			bash reinstall-esp-idf.sh h
			bash reinstall-esp-idf.sh -h
			bash reinstall-esp-idf.sh --help

```

## Helpful stuff
```
cron:
    reinstall from master everyday at 8pm, logging out users with warn delays and rebooting after
	    crontab -e
	    0 8 * * * bash $HOME/esp/esp-install-custom/reinstall-esp-idf.sh cron

manually wipe logs: 
	rm $ESPIDF_INSTALLDIR/install.log; rm $ESPIDF_INSTALLDIR/version-data.txt; touch $ESPIDF_INSTALLDIR/install.log; touch $ESPIDF_INSTALLDIR/version-data.txt;

monitor log file during install:
	tail -n 75 $ESPIDF_INSTALLDIR/install.log;
```