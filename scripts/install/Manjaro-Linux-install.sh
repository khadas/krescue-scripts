#!/bin/sh

## hyphop ##

#= Manjaro-Linux-install

DESCRIPTION="\
Manjaro-Linux
=============

Free fast and secure Linux based operating system for everyone, suitable
replacement to Windows or MacOS with different Desktop Environments.

    REL=p10 from 20210912

    TYPES= gnome | kde-plazma | mate | minimal | sway | xfce
    BOARDS= VIM2 | VIM3

" #DESCRIPTION_END

LABEL="Manjaro"
BOARDS="VIM2 VIM3 #"

## USAGE examples

#  curl -jkL https://raw.githubusercontent.com/khadas/krescue/master/scripts/Manjaro-Linux-install.sh | sh -s -
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
    DL=https://github.com/manjaro-arm
#/vim3-images/releases/download/21.10/Manjaro-ARM-gnome-vim3-21.10.img.xz

[ "$REL" ] || \
    REL=21.10

case $REL in
    21.10)
    REL_DATE=20211018
    FMT=img.xz
    ;;
esac

[ "$FMT" ] || \
    FMT=img.xz

TITLE="Manjaro-Linux $REL($REL_DATE) - installation for: $BOARD ..."

[ "$GUI" ] && {
[ "$TYPE" ] || \
    dialog --title "$TITLE" --menu \
    "Select installation TYPE:" 0 0 0 \
    "gnome" "" \
    "kde-plazma" "" \
    "mate" "" \
    "minimal" "" \
    "sway" "" \
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

case $BOARD in
    VIM1)board=vim1;;
    VIM2)board=vim2;;
    VIM3)board=vim3;;
    VIM3L)board=vim3l;;
    Edge)board=edge;;
    *)boar=$BOARD
esac

# can chouse any other rootfs source
IMAGE=Manjaro-ARM-$TYPE-$board-$REL.$FMT
SRC=$DL/$board-images/releases/download/$REL/$IMAGE

[ "$TEST" ] && {
echo "TEST $SRC replace to"
DL=http://router_:8081/img
SRC=$DL/$IMAGE
echo "> $SRC"
}

echo "download and extract $SRC"
case $FMT in
    img*)
echo "curl -A downloader -jkL $SRC | pixz -dc > $DST"
curl -A downloader -jkL "$SRC" | pixz -dc > $DST || FAIL decompression
echo wait...
sync
sfdisk --dump $DST | tee /tmp/parts.data
partx -u $DST -v || true
blkid | tee /tmp/parts.type
mount ${DST}p1 $BOOT || FAIL "mount boot"
# deactivate EFI
#mv $BOOT/EFI $BOOT/.EFI
# clean boot trash
#rm -rf $BOOT/*
mount ${DST}p2 $SYS || FAIL "mount system root"
    ;;
    *) # tar
curl -A downloader -jkL $SRC | pixz -dc | tar -xf- -C $SYS
    ;;
esac

#logo
curl -A downloader -jkL http://dl.khadas.com/.dl/logos/manjaro.bmp.gz -o $BOOT/splash.bmp

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
