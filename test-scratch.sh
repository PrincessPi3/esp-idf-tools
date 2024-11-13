alias get_idf 2>/dev/null
ret=$?
if [ $ret -eq 1 ]; then
	echo "aliasnant not found"
fi
