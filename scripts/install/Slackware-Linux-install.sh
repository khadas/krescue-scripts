#!/bin/sh

## hyphop ##

#= Slackware-Linux-install

## USAGE examples

#  curl dl.khadas.com/s/Slackware-Linux-install.sh | sh -s -
#  or local usage
#  ssh root@krescue.local < Slackware-Linux-install.sh

# https://arm.slackware.com/

set -e -o pipefail

BOARD=$(tr -d '\0' < /sys/firmware/devicetree/base/model || echo Khadas)
echo "Slackware Linux installation for $BOARD ..."

# checks
echo "check network connection..."
ping -c1 -w2 1.1.1.1 || (echo 'plz check/setup network connection `krescue`'; exit 1)
# stop prev session
pkill -f downloader || true
sleep 1
grep $(mmc_disk) /proc/mounts && umount $(mmc_disk)p1

# create partitions
echo "label: dos" | sfdisk $(mmc_disk)
echo "part1 : start=16M," | sfdisk $(mmc_disk)

# create rootfs
mkfs.ext4 -L ROOT $(mmc_disk)p1 < /dev/null
mkdir -p system && mount $(mmc_disk)p1 system

