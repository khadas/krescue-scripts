#!/bin/sh

## hyphop ##

#= Fedora-Linux-install

## USAGE examples

#  curl -jkL https://raw.githubusercontent.com/khadas/krescue-scripts/master/scripts/install/Fedora-Linux-install.sh | sh -s -
#  or local usage
#  ssh root@krescue.local < Fedora-Linux-install.sh
#  or Workstation edition
#  ssh root@krescue.local TYPE=Workstation shell < Fedora-Linux-install.sh

# install Workstation edition example
# curl -jkL https://raw.githubusercontent.com/khadas/krescue-scripts/master/scripts/install/Fedora-Linux-install.sh | TYPE=Workstation sh -s -

# install server edition by default
# curl -jkL https://raw.githubusercontent.com/khadas/krescue-scripts/master/scripts/install/Fedora-Linux-install.sh | sh -s -

## PROBLEMS

# + display 4k not usable plz use 2k
# + ethernet bug can solved with
# sudo rmmod dwmac_generic
# sudo modprobe dwmac_generic
# + default kernel old have many bugs
# sudo dnf update
# + need manual update dtb for UEFI boot
# sudo cp -av /boot/dtb/rockchip /boot/efi/dtb
# sudo cp -av /boot/dtb/amlogic  /boot/efi/dtb
# + VIM3 VIM3L no sound kernel
# # CONFIG_COMMON_CLK_AXG_AUDIO is not set
# need rebuild kernel

set -e -o pipefail

DST=$(mmc_disk)

BOARD=$(tr -d '\0' < /sys/firmware/devicetree/base/model || echo Khadas)
echo "ArchLinux installation for $BOARD ... > $DST"

# checks 
echo "check network connection..."
ping -c1 -w2 1.1.1.1 || (echo plz check or setup network connection; exit 1)
# stop prev session
pkill -f downloader || true
sleep 1

# fedora have xfs boot partition - cool ;-)
modules_download_ipk fs
modprobe xfs || exit 1
modprobe btrfs || exit 1

#echo partx -d $DST -v
#partx -d $DST --nr :10 -v || sfdisk --delete -Wauto -wauto -f $DST || true

for p in $(grep -e "^${DST}p." /proc/mounts); do
    [ -b "$p" ] && echo umount $p && umount $p
done

[ "$REL" ] || \
    REL=34-1.2
[ "$TYPE" ] || \
    TYPE=Server
[ "$DL" ] || \
    DL=https://download.fedoraproject.org/pub/fedora/linux/releases

#TYPE=Workstation
#TYPE=Server
#DL=https://mirrors.tuna.tsinghua.edu.cn/fedora/releases

SRC=$DL/${REL%-*}/$TYPE/aarch64/images/Fedora-$TYPE-$REL.aarch64.raw.xz

[ "$TEST" ] && {
echo "TEST $SRC replace to"
DL=http://router_:8081/img/
SRC=$DL/Fedora-$TYPE-$REL.aarch64.raw.xz
echo "> $SRC"
}

IMG=$(basename "$SRC")
unpack=pixz

case $IMG in
    *.xz)  unpack=pixz;;
    *.gz)  unpack=pigz;;
    *.zst) unpack=zstd;;
esac

echo "download and extract $SRC"
echo "$unpack: image $IMG > $DST"
#curl -A downloader -jkL $SRC -o/tmp/$IMG
curl -A downloader -jkL $SRC | $unpack -dc > $DST
echo wait...
sync

sfdisk --dump $DST | tee /tmp/parts.data
partx -u $DST -v || true
blkid

## oops boot partition start at 2048 - its ugly and not enough for uboot ;-)
#/dev/mmcblk1p1 : start=        2048, size=     1228800, type=6, bootable

## uboot efi boot need get dtb from efi part or cant boot kernel with wrong dtb
mkdir -p 1 2 3
mount ${DST}p1 1
mount ${DST}p2 2
mount ${DST}p2 3
mkdir -p 1/dtb
# copy amlogic and rockhip dtb's
cp -a 2/dtb/aml* 2/dtb/rock* 1/dtb
# copy wifi fw
cp -a /lib/firmware/brcm 3/root/lib/firmware

# more verbose boot
#sed -i "s/ rhgb quiet console=tty0//" 2/grub2/grub.cfg
#grep kernelopts= 2/grub2/grub.cfg
#KERNEL_ARGS=video=HDMI-A-1:1920x1080@60e

for c in 2/loader/entries/*.conf; do
    [ -s "$c" ] || continue
    sed -i "s/ rhgb quiet console=tty0/$KERNEL_ARGS/" $c
    echo "efi grub config: $c"
    cat $c
done

[ "" ] && {
chmod 0777 system/etc/rc.local
# setup secure tty
echo ttyAML0 >> system/etc/securetty
echo ttyFIQ0 >> system/etc/securetty
}

umount 1 2 3

#exit 0

echo "install uboot to eMMC"
# only into boots area
mmc_update_uboot online boots

echo "optional install uboot to SPI flash"
case $BOARD in
*vim|*VIM) echo "skipped for $BOARD";;
*)
spi_update_uboot online -k && echo need poweroff and poweron device again
esac

echo "Fedira Linux installation for $BOARD : DONE"
# again show parts
blkid
# DONE
echo "plz reboot device"
