echo 'alias run_esp_reinstall="git -C $HOME/esp/esp-install-custom pull; cat $HOME/esp/esp-install-custom/version.txt; bash $HOME/esp/esp-install-custom/reinstall-esp-idf.sh "' >> ~/.zshrc

echo 'alias esp_monitor="tail -n 75 -f $ESPIDF_INSTALLDIR/install.log;"' >> ~/.zshrc

echo 'alias esp_logs="less $ESPIDF_INSTALLDIR/install.log; less $ESPIDF_INSTALLDIR/version-data.txt"' >> ~/.zshrc

run_esp_reinstal clear