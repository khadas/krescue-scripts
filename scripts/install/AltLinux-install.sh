#!/bin/sh

## hyphop ##

#= AltLinux-install

DESCRIPTION="\
Alt-Linux
=========

ALT Linux is a set of Russian operating systems based on RPM Package
Manager and built on a Linux kernel and Sisyphus package repository...

    REL=p10 from 20210912
    TYPES= builder | lxqt | mate | xfce
" #DESCRIPTION_END

BOARDS="VIM1 VIM2 VIM3 VIM3L Edge #"

## USAGE examples

#  curl -jkL https://raw.githubusercontent.com/khadas/krescue/master/scripts/AltLinux-install.sh | sh -s -
#  or local usage
#  ssh root@krescue.local < AltLinux-install.sh

set -e -o pipefail

[ "$BOARD" ] || \
BOARD=$(board_name 2>/dev/null || echo Undefined)

[ "$DST" ] || \
DST=$(mmc_disk 2>/dev/null || echo /dev/null)

FAIL(){
echo "[e] $@">&2
exit 1
}

GUI_SEL=/tmp/gui_sel

[ "$DL" ] || \
    DL=http://nightly.altlinux.org

[ "$REL" ] || \
    REL=p10

case $REL in
    p10)
    REL_DATE=20211212
    FMT=img.xz
    ;;
esac

[ "$FMT" ] || \
    FMT=tar.xz

TITLE="Alt-Linux $REL($REL_DATE) - installation for: $BOARD ..."

[ "$GUI" ] && {
[ "$TYPE" ] || \
    dialog --title "$TITLE" --menu \
    "Select installation TYPE:" 0 0 0 \
    "builder" "" \
    "lxqt" "" \
    "mate" "" \
    "xfce" "" \
    2>$GUI_SEL || exit 1
    TYPE=$(cat $GUI_SEL 2>/dev/null)
    clear
}

[ "$TYPE" ] || \
    TYPE=xfce

echo "$TITLE +$TYPE > $DST"
echo "$BOARDS" | grep -q -m1 "$BOARD" || FAIL "not suitable for this $BOARD device"

# checks
# echo "check network connection..."
net_check_default_route 1>/dev/null 2>&1 || \
    FAIL "Please check or setup network connection"
# stop prev session
pkill -f downloader || true
sleep 1

for p in $(grep -e "^${DST}p." /proc/mounts); do
    [ -b "$p" ] && echo umount $p && umount $p
done

SYS=mnt.system
BOOT=mnt.boot

mkdir -p $SYS $BOOT

case $FMT in
    img*)
    ;;
    *)
# create partitions
echo "label: dos" | sfdisk $DST
echo "part1 : start=16M," | sfdisk $DST
# create rootfs
mkfs.ext4 -L ROOT ${DST}p1 < /dev/null
mkdir -p $SYS && mount ${DST}p1 $SYS
    ;;
esac

# can chouse any other rootfs source
#SRC=http://nightly.altlinux.org/p9-aarch64/release/alt-p9-jeos-sysv-20210612-aarch64.tar.xz
SRC=$DL/$REL-aarch64/release/alt-$REL-$TYPE-$REL_DATE-aarch64.$FMT

#http://nightly.altlinux.org/sisyphus-aarch64/current/
#http://nightly.altlinux.org/sisyphus-aarch64/current/regular-xfce-latest-aarch64.img.xz
#http://nightly.altlinux.org/sisyphus-aarch64/current/regular-mate-latest-aarch64.img.xz
#http://nightly.altlinux.org/sisyphus-aarch64/current/regular-lxqt-latest-aarch64.img.xz
#http://nightly.altlinux.org/sisyphus-aarch64/current/regular-jeos-systemd-latest-aarch64.img.xz
#http://nightly.altlinux.org/sisyphus-aarch64/current/regular-lxde-latest-aarch64.tar.xz

[ "$TEST" ] && {
echo "TEST $SRC replace to"
DL=http://router_:8081/img/
SRC=$DL/alt-$REL-$TYPE-$REL_DATE-aarch64.$FMT
echo "> $SRC"
}

echo "download and extract $SRC"
case $FMT in
    img*)
echo "curl -A downloader -jkL $SRC | pixz -dc > $DST"
curl -A downloader -jkL "$SRC" | pixz -dc > $DST || FAIL decompression
echo wait...
sync
sfdisk --dump $DST | tee /tmp/parts.data | sfdisk --force $DST
#partx -u $DST -v || true
blkid | tee /tmp/parts.type
mount ${DST}p1 $BOOT || FAIL "mount boot"
# deactivate EFI
mv $BOOT/EFI $BOOT/.EFI
# clean boot trash
rm -rf $BOOT/*
mount ${DST}p2 $SYS || FAIL "mount system root"
    ;;
    *) # tar
curl -A downloader -jkL $SRC | pixz -dc | tar -xf- -C $SYS
    ;;
esac

# setup host name
echo ${BOARD// /-} > $SYS/etc/hostname

# fix dtb paths
for a in $SYS/lib/devicetree/*-alt1; do ln -s . $a/amlogic; ln -s . $a/rockchip; done

# maybe need fix extlinux config
cp $SYS/boot/extlinux/extlinux.conf $SYS/boot/extlinux/extlinux.conf.bak
sed -i s/console=tty1/earlyprintk/ $SYS/boot/extlinux/extlinux.conf

# setup secure tty
echo ttyAML0 >> $SYS/etc/securetty
echo ttyFIQ0 >> $SYS/etc/securetty

# copy wifi fw
cp -a /lib/firmware/brcm $SYS/lib/firmware

# unlock root
chroot $SYS passwd -d root

#logo
curl -A downloader -jkL http://dl.khadas.com/.dl/logos/Logo_alt_company.bmp.gz -o $BOOT/splash.bmp

umount $SYS $BOOT || true

echo "install uboot to eMMC"
mmc_update_uboot online

echo "optional install uboot to SPI flash"
case $BOARD in
*vim|*VIM) echo "skipped for $BOARD";;
*)
spi_update_uboot online -k && echo need poweroff and poweron device again
esac

# DONE
echo "$TITLE : DONE"
# again show parts
blkid
echo "plz reboot device"

## __END__

