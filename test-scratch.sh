alias get_idf #2>/dev/null
ret=$?
if [ $ret -eq 1 ]; then
	echo "get_idf not found"
fi

alias run_esp_reinstall #2>/dev/null
ret=$?
if [ $ret -eq 1 ]; then
	echo "run_esp_reinstall not found"
fi

alias esp_monitor #2>/dev/null
ret=$?
if [ $ret -eq 1 ]; then
	echo "esp_monitor not found"
fi

alias esp_logs #2>/dev/null
ret=$?
if [ $ret -eq 1 ]; then
	echo "esp_monitor not found"
fi

if [ -z $ESPIDF_INSTALLDIR ]; then
	echo "ESPIDF_INSTALLDIR not found"
fi