#!/bin/sh

## hyphop ##

#= Gentoo-Linux-install

## USAGE examples

#  curl -jkL https://raw.githubusercontent.com/khadas/krescue/master/scripts/Gentoo-Linux-install.sh | sh -s -
#  curl dl.khadas.com/s/Gentoo-Linux-install.sh | sh -s -
#  or local usage
#  ssh root@krescue.local < Gentoo-Linux-install.sh

# https://wiki.gentoo.org/wiki/Handbook:Main_Page .
# https://www.gentoo.org/

set -e -o pipefail

BOARD=$(tr -d '\0' < /sys/firmware/devicetree/base/model || echo Khadas)
echo "ArchLinux installation for $BOARD ..."

# checks
echo "check network connection..."
ping -c1 -w2 1.1.1.1 || (echo 'plz check or setup network connection `krescue`'; exit 1)
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

# can chouse any other rootfs source

# can chouse any other rootfs source
# https://wiki.gentoo.org/wiki/Handbook:ARM64/Installation/About
# https://www.gentoo.org/downloads/
# https://mirror.bytemark.co.uk/gentoo/releases/arm64/autobuilds/
# https://mirror.bytemark.co.uk/gentoo/experimental/arm64/musl/stage3-arm64-musl-vanilla-20200605.tar.bz2
# https://mirror.bytemark.co.uk/gentoo/experimental/arm64/musl/stage3-arm64-musl-hardened-20200605.tar.bz2

SRC=https://mirror.bytemark.co.uk/gentoo/releases/arm64/autobuilds/current-stage3-arm64/stage3-arm64-20210613T200518Z.tar.xz
SRC=https://mirror.bytemark.co.uk/gentoo/releases/arm64/autobuilds/current-stage3-arm64-systemd/stage3-arm64-systemd-20210613T200518Z.tar.xz
SRC=https://mirror.bytemark.co.uk/gentoo/releases/arm64/autobuilds/current-stage3/stage3-arm64-20210613T200518Z.tar.xz

#SRC=http://router_:8081/img/

echo "download and extract $SRC"
curl -A downloader -jkL $SRC | pixz -dc | tar -xf- -C system

mount -o bind /proc system/proc
mount --rbind /sys system/sys
mount --make-rslave system/sys
mount --rbind /dev system/dev
mount --make-rslave system/dev
mkdir -p system/run/shm
mount --rbind /run/shm system/run/shm

# setup host name
echo ${BOARD// /-} > system/etc/hostname
echo 1.1.1.1 > system/etc/resolv.conf

chroot /mnt/gentoo /bin/env -i TERM=$TERM /bin/bash

cat <<'END' | tee -a /tmp/setup.sh
source /etc/profile
env-update
export PS1="(CHROOT) $PS1"
#emerge-webrsync
emerge --sync
eselect profile list
#Available profile symlink targets:
#  [1]   default/linux/arm64/17.0 (stable) *
#  [2]   default/linux/arm64/17.0/desktop (stable)
#  [3]   default/linux/arm64/17.0/desktop/gnome (stable)
#  [4]   default/linux/arm64/17.0/desktop/gnome/systemd (stable)
#  [5]   default/linux/arm64/17.0/desktop/plasma (stable)
#  [6]   default/linux/arm64/17.0/desktop/plasma/systemd (stable)
#  [7]   default/linux/arm64/17.0/desktop/systemd (stable)
#  [8]   default/linux/arm64/17.0/developer (stable)
#  [9]   default/linux/arm64/17.0/systemd (stable)
#  [10]  default/linux/arm64/17.0/big-endian (exp)
#  [11]  default/linux/arm64/17.0/musl (exp)
#  [12]  default/linux/arm64/17.0/musl/hardened (exp)
#

emerge --ask --verbose --update --deep --newuse @world
emerge --info | grep ^USE
#https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Mounting_the_boot_partition
#https://wiki.gentoo.org/wiki/Raspberry_Pi_3_64_bit_Install
#https://forums.gentoo.org/viewtopic-p-8304244.html#8304244


END

# fix dtb paths
#for a in system/lib/devicetree/*-alt1; do ln -s . $a/amlogic; ln -s . $a/rockchip; done

# maybe need fix extlinux config
#cp system/boot/extlinux/extlinux.conf system/boot/extlinux/extlinux.conf.bak
# sed -i s/console=tty1/earlyprintk/ system/boot/extlinux/extlinux.conf

# setup secure tty
echo ttyAML0 >> system/etc/securetty
echo ttyFIQ0 >> system/etc/securetty

umount system

echo "install uboot to eMMC"
mmc_update_uboot online

echo "optional install uboot to SPI flash"
case $BOARD in
*vim|*VIM) echo "skipped for $BOARD";;
*)
spi_update_uboot online -k && echo need poweroff and poweron device again
esac

# DONE
echo "Gentoo Linux installation for $BOARD : DONE"
echo "plz reboot device"
