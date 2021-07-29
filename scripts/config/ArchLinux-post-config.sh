#!/bin/sh

## hyphop ##

#= ArchLinux-post-config

## USAGE examples

#  curl -jkL https://raw.githubusercontent.com/khadas/krescue/master/scripts/ArchLinux-post-config.sh | sh -s -
#  or local usage
#  ssh root@krescue.local < ArchLinux-post-config.sh

set -e -o pipefail

BOARD=$(tr -d '\0' < /sys/firmware/devicetree/base/model || echo Khadas)
echo "ArchLinux post-config for $BOARD ..."

exit 0


useradd --create-home --groups "adm,disk,lp,wheel,audio,video,cdrom,usb,users,plugdev,portage,cron,gpio,i2c,spi" --shell /bin/bash --comment "Sakaki" sakaki
