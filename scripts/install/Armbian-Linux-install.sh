#!/bin/sh

## hyphop ##

#= Armbian-Linux-install

DESCRIPTION="\
Armbian-Linux
=============

Armbian is a Debian and Ubuntu based computer operating system for ARM
development boards.

https://armbian.com https://docs.armbian.com https://forum.armbian.com

    REL=? from Aug 26 2021

    TYPES= Bullseye | Buster | Focal | Hirsute ...
    BOARDS= VIM1 | VIM2 | VIM3 | Edge

" #DESCRIPTION_END

LABEL="Armbian"
BOARDS="VIM1 VIM2 VIM3 Edge #"

## USAGE examples

#  curl -jkL https://raw.githubusercontent.com/khadas/krescue/master/scripts/Armbian-Linux-install.sh | sh -s -
#  or local usage
#  ssh root@krescue.local < Armbian-Linux-install.sh
#  or remote
#  ssh root@krescue shell scripts scripts/install/Armbian-Linux-install.sh

set -e -o pipefail

GET="curl -A krescue_downloader -jkL"

[ "$BOARD" ] || \
BOARD=$(board_name 2>/dev/null || echo Undefined)

case $BOARD in
    VIM1)board=vim1;;
    VIM2)board=vim2;;
    VIM3)board=vim3;;
    VIM3L)board=vim3l;;
    Edge)board=edge;;
    *)boar=$BOARD
esac

[ "$DST" ] || \
DST=$(mmc_disk 2>/dev/null || echo /dev/null)

FAIL(){
echo "[e] $@">&2
exit 1
}

GUI_SEL=/tmp/gui_sel

[ "$DL" ] || \
    DL=https://redirect.armbian.com

#[ "$REL" ] || \
#    REL=current

case $REL in
    *)
    REL_DATE=current
    FMT=img.xz
    ;;
esac

[ "$FMT" ] || \
    FMT=img.xz

TITLE="Armbian-Linux $REL($REL_DATE) - installation for: $BOARD ..."

[ "$GUI" ] && {

[ "$TYPE" ] || \
    case $BOARD in
	VIM3L)
    dialog --title "$TITLE" --menu \
    "Select installation TYPE:" 0 0 0 \
    "nightly" "Nightly - testing ..." \
    "archive" "Archive ..." \
    2>$GUI_SEL || exit 2
	;;
	VIM3)
    dialog --title "$TITLE" --menu \
    "Select installation TYPE:" 0 0 0 \
    "Bullseye_current" "Debian - Bullseye 11.x" \
    "Buster_current" "Debian - Buster 10.x" \
    "Focal_current" "Ubuntu - Focal 20.x" \
    "Hirsute_edge_budgie" "Ubuntu - Hirsute Budgie 21.x" \
    "Hirsute_edge_cinnamon" "Ubuntu - Hirsute Cinnamon 21.x" \
    "Hirsute_edge_xfce" "Ubuntu - Hirsute Xfce 21.x" \
    "nightly" "Nightly - testing ..." \
    "archive" "Archive ..." \
    2>$GUI_SEL || exit 2
	;;
	Edge)
    dialog --title "$TITLE" --menu \
    "Select installation TYPE:" 0 0 0 \
    "Bullseye_current" "Debian - Bullseye 11.x" \
    "Buster_current" "Debian - Buster 10.x" \
    "Focal_current" "Ubuntu - Focal 20.x" \
    "Focal_current_budgie" "Ubuntu - Focal Budgie 20.x" \
    "Focal_current_cinnamon" "Ubuntu - Focal Cinnamon 20.x" \
    "Hirsute_edge" "Ubuntu - Hirsute 21.x" \
    "Hirsute_edge_xfce" "Ubuntu - Hirsute Xfce 21.x" \
    "nightly" "Nightly - testing ..." \
    "archive" "Archive ..." \
    2>$GUI_SEL || exit 2
	;;
	*)# VIM2 VIM1
    dialog --title "$TITLE" --menu \
    "Select installation TYPE:" 0 0 0 \
    "Bullseye_current" "Debian - Bullseye 11.x" \
    "Buster_current" "Debian - Buster 10.x" \
    "Focal_current" "Ubuntu - Focal 20.x" \
    "Focal_current_budgie" "Ubuntu - Focal Budgie 20.x" \
    "Focal_current_cinnamon" "Ubuntu - Focal Cinnamon 20.x" \
    "Focal_current_xfce" "Ubuntu - Focal Xfce 20.x" \
    "Hirsute_edge_budgie" "Ubuntu - Hirsute Budgie 21.x" \
    "Hirsute_edge_cinnamon" "Ubuntu - Hirsute Cinnamon 21.x" \
    "Hirsute_edge_xfce" "Ubuntu - Hirsute Xfce 21.x" \
    "nightly" "Nightly - testing ..." \
    "archive" "Archive ..." \
    2>$GUI_SEL || exit 2
	;;
    esac
    TYPE=$(cat $GUI_SEL 2>/dev/null)

case "$TYPE" in
    nightly|archive)
    MIRROR="/"
    DL="https://imola.armbian.com"

    # scan http index
    PRE="/dl/khadas-$board/$TYPE/"
    PRS=${PRE//\//\\\/}
    SCAN="$DL$PRE"
    T="/tmp/$LABEL.$board.$TYPE"

    $GET "$SCAN" -o"$T" || exit 3
    sed "s/</\n/g" "$T" | grep -o -e \"/\.*\.$FMT\" > $T.list || exit 4

    echo "--title \"$TITLE\" --menu \"Select installation TYPE:\" 0 0 0" > $T.opts
    sed "s/$PRS//" $T.list | \
	sed "s/z\"/z\" \"\"/"  >> $T.opts

    case $BOARD in
	*)
    dialog --file $T.opts 2>$GUI_SEL || exit 2
	;;
    esac

    TYPE=$(cat $GUI_SEL 2>/dev/null)
    IMAGE="$TYPE"
    SRC="$SCAN/$IMAGE"
    ;;
esac ## Nightly END ##

[ "$MIRROR" ] || \
    dialog --title "$TITLE" \
    --menu  \
    "Select download region MIRROR:" 0 0 0 \
    "" "Auto" \
    "/region/EU" "Europe" \
    "/region/NA" "USA" \
    "/region/AS" "Asia" \
    2>$GUI_SEL || exit 2
    MIRROR=$(cat $GUI_SEL 2>/dev/null)
#--cancel-label "Skip to Default" \
#   --default-button cancel \

clear

} # GUI END

[ "$TYPE" ] || \
    TYPE=Focal_current

echo "$TITLE +$TYPE($MIRROR) > $DST"
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
[ "$IMAGE" ] || \
    IMAGE=$TYPE
[ "$SRC" ] || \
    SRC=$DL$MIRROR/khadas-$board/$IMAGE

[ "$TEST" ] && {
echo "TEST $SRC replace to"
DL=http://router_:8081/img
SRC=$DL/$IMAGE
echo "> $SRC"
}

echo "download and extract $SRC"
case $FMT in
    img*)
echo "$GET $SRC | pixz -dc > $DST"
$GET "$SRC" | pixz -dc > $DST || FAIL decompression
echo wait...
sync
sfdisk --dump $DST | tee /tmp/parts.data | sfdisk --force $DST
#partx -u $DST -v || true
blkid | tee /tmp/parts.type
mount ${DST}p1 $BOOT || FAIL "mount boot"
# deactivate EFI
#mv $BOOT/EFI $BOOT/.EFI
# clean boot trash
#rm -rf $BOOT/*
#mount ${DST}p2 $SYS || FAIL "mount system root"
    ;;
    *) # tar
$GET $SRC | pixz -dc | tar -xf- -C $SYS
    ;;
esac

#logo
#curl -A downloader -jkL http://dl.khadas.com/.dl/logos/armbian.bmp.gz -o $BOOT/splash.bmp
#cp $BOOT/boot/boot.bmp $BOOT/splash.bmp || true

F=$BOOT/boot/armbian_first_run.txt.template
T=$BOOT/boot/armbian_first_run.txt
[ "$GUI" -a -s "$F" ] && {
    dialog --title "Armbian first run configuration" \
	--cancel-label "Skip configuration" \
	--default-button cancel \
	--editbox "$F" 0 0 2>"$T" || rm "$T"
}

umount $BOOT || true

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
