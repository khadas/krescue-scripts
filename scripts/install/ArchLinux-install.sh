#!/bin/sh

## hyphop ##

#= ArchLinux-install

DESCRIPTION="\
Arch Linux
==========

Arch Linux ARM is a port of Arch Linux for ARM processors. Its design
philosophy is 'simplicity and full control to the end user,' and like its
parent operating system Arch Linux, aims to be very Unix-like.
"
#DESCRIPTION_END

#% BOARDS VIM1 VIM2 VIM3 VIM3L Edge #

## USAGE examples

#  curl -jkL https://raw.githubusercontent.com/khadas/krescue/master/scripts/ArchLinux-install.sh | sh -s -
#  or local usage
#  ssh root@krescue.local < ArchLinux-install.sh

set -e -o pipefail

[ "$DST" ] || \
DST=$(mmc_disk 2>/dev/null || echo /dev/null)

FAIL(){
echo "[e] $@">&2
exit 1
}

[ "$BOARD" ] || \
BOARD=$(board_name 2>/dev/null || echo Undefined)

echo "Arch Linux installation for: $BOARD ... > $DST"
echo "$BOARDS" | grep -q -m1 "$BOARD" || FAIL "not suitable for this $BOARD device"

# checks
# echo "check network connection..."
net_check_default_route 1>/dev/null 2>&1 || \
    FAIL "Please check or setup network connection"

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
SRC=http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
#SRC=http://router_:8081/img/ArchLinuxARM-aarch64-latest.tar.gz

echo "download and extract $SRC"
curl -A downloader -jkL $SRC | pigz -dc | tar -xf- -C system

echo "setup extlinux config"
mkdir -p system/boot/extlinux/
cat <<-END | tee system/boot/extlinux/extlinux.conf
label ArchLinux
kernel /boot/Image.gz
initrd /boot/initramfs-linux.img
fdtdir /boot/dtbs
append root=LABEL=ROOT rw quiet
END

# setup rootfs
echo LABEL=ROOT / auto errors=remount-ro 1 1 >> system/etc/fstab

# setup host name
echo ${BOARD// /-} > system/etc/hostname

# setup dhcp for ethernet
echo dhcpcd eth0 -d > system/etc/rc.local
chmod 0777 system/etc/rc.local

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
echo "ArchLinux installation for $BOARD : DONE"
echo "plz reboot device"
