#!/bin/sh

## hyphop ##

#= Ubuntu focal Generic install to nvme

## USAGE examples

DESCRIPTION="\
Generic-Ubuntu NVME/USB/SD installation
=======================================

Generic Ubuntu Image for NVME / USB / SD usage

    - Linux-5.14-rc5_arm64..V1.0.7-210824

    REL=focal

    TYPES= minimal

    BOARDS= VIM1 | VIM2 | VIM3 | VIM3L | Edge
" #DESCRIPTION_END

LABEL="Ubuntu"
TYPE=minimal
REL=focal

BOARDS="VIM1 VIM2 VIM3 VIM3L Edge #"

set -e -o pipefail

CMD(){
echo "# $@">&2
"$@"
}

FAIL(){
[ "$GUI" ] || echo "[e] $@">&2
TITLE=Error umsg "$@"
exit 1
}

[ "$BOARD" ] || \
BOARD=$(board_name 2>/dev/null || echo Undefined)

TITLE="Generic Ubuntu $REL - $TYPE :: $DST installation for: $BOARD ..."

GUI_SEL=/tmp/gui_sel

[ "$GUI" ] && {
[ "$DST" ] || \
    dialog --title "$TITLE" --menu \
    "Select installation TYPE:" 0 0 0 \
    "EMMC" "default" \
    "NVME" "" \
    "USB" "" \
    "SD" "" \
    2>$GUI_SEL || exit 1
    DST=$(cat $GUI_SEL 2>/dev/null)
    clear
}

[ "$DST" ] || \
    DST=NVME

case $DST in
    EMMC) DEST=$(mmc_disk || true) ;;
    NVME) DEST=$(nvme_disk || true) ;;
    USB)  DEST=$(usb_disk || true)  ;;
    SD)   DEST=$(sd_disk || true)   ;;
esac

[ -b "$DEST" ] || FAIL "$DST $DEST disk not found"

GET="curl -A krescue_downloader -jkL"

TITLE="Generic Ubuntu $REL - $TYPE :: $DST($DEST) installation for: $BOARD ..."

[ "$SRC" ] || \
    SRC=https://dl.khadas.com/Firmware/Krescue/images/Generic_Ubuntu-minimal-focal_Linux-5.14-rc5_arm64_SD-USB_V1.0.7-210824-develop.img.xz

echo "$TITLE"

# checks
# echo "check network connection..."
net_check_default_route 1>/dev/null 2>&1 || \
    FAIL "Please check or setup network connection"
# stop prev session
pkill -f downloader || true
sleep 1

case $SRC in
    *.xz) unpack=pixz ;;
    *.gz) unpack=pigz ;;
    *)    unpack=cat  ;;
esac

echo "get $SRC | $unpack > $DEST"

(
grep -o -E $DEST\\S+\\s /proc/mounts 2>/dev/null | while read l ; do
    CMD umount $l
done
) || true

partx -d --nr 0:100 $DEST || true

echo wait...
$GET $SRC | $unpack -dc > $DEST || FAIL "write / decompression"
echo wait...
sync

gpt_fix $DEST

[ "$GUI" ] && {
[ "$BOOT" ] || \
    dialog --title "$TITLE" --menu \
    "update/write uboot into:" 0 0 0 \
    "eMMC" "boot areas" \
    "SPI" "flash" \
    "skip" "ignore" \
    2>$GUI_SEL || exit 1
    BOOT=$(cat $GUI_SEL 2>/dev/null)
    clear
}

case "$BOOT" in
    eMMC)
    echo "install uboot to eMMC"
    mmc_update_uboot online
    ;;
    SPI)
echo "optional install uboot to SPI flash"
case $BOARD in
*vim|*VIM) echo "skipped for $BOARD";;
*)
spi_update_uboot online -k && echo need poweroff and poweron device again
esac
    ;;
esac

echo "$TITLE - DONE"

blkid $DEST*

sleep 1