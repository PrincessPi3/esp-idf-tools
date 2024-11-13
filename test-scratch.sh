function checkAlias() {
	echo "Testing $1"
	alias $1 2>/dev/null
	ret=$?
	echo -e "\tretcode: $ret"
	if [ $ret -eq 1 ]; then
		echo "$1 not found"
	else
		echo "$1: $(alias $1)"
	fi

	return $ret
}

checkAlias get_idf
checkAlias run_esp_reinstall
checkAlias esp_monitor
checkAlias esp_logs
checkAlias notarealone

# if [ -z $ESPIDF_INSTALLDIR ]; then
# 	echo "ESPIDF_INSTALLDIR not found"
# else
# 	echo "ESPIDF_INSTALLDIR: $ESPIDF_INSTALLDIR"
# fi

