# esp-idf custom installer/reinstaller
installs/reinstalls full esp-idf with my own additions on linux.  
pulls from master so its the very latest

built for debian-like systems

`git clone https://github.com/PrincessPi3/esp-install-custom.git ~`
`bash ~/reinstall-esp-idf.sh`

scripts added:
`build` idf.py build
`changebaud` prompts to enter a new baud
`changeesp` prompts to type in esp32s3, esp32c6, etc
`changeport` opens a menu to select a serial port
`clean` idf.py clean
`fullclean` fully resets a project, 'idf.py fullclean' plus remove the build dir and delete some temp and backup files
`rebuildfull` does a `fullclean` but also an `erase-flash` and also `setup`
`setup` same as running 'idf.py set-target $ESPTARGET; idf.py menuconfig; idf.py build'
`flash` idf.py flash
`monitor` idf.py monitor
`erase-flash` idf.py erase-flash
`save-defconfig` idf.py save-defconfig