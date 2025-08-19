#!/bin/bash
espidf=$(du -b -d 0 ~/esp/esp-idf | awk '{print $1}')
espdevkits=$(du -b -d 0 ~/esp/esp-dev-kits | awk '{print $1}')
espidftools=$(du -b -d 0 ~/esp/esp-idf-tools | awk '{print $1}')
custom_bin=$(du -b -d 0 ~/esp/.custom_bin | awk '{print $1}')
espressif=$(du -b -d 0 ~/.espressif | awk '{print $1}')

bytes=$(($espidf + $espdevkits + $espidftools + $custom_bin + $espressif))
human=$(numfmt --to=iec-i --suffix=B $bytes)

echo "Total size of ESP-IDF related directories: $bytes bytes ($human)"