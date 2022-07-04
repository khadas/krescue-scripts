#!/bin/sh

## hyphop ##

#= Ubuntu focal Generic install to nvme

## USAGE examples

DESCRIPTION="\
VIM4 Ubuntu NVME/USB/SD installation
====================================

Ubuntu Image for NVME / USB / SD usage

    - wip... beta...

    REL=22.04

    TYPES= server

    BOARDS= VIM4
" #DESCRIPTION_END

LABEL="Ubuntu"
TYPE=server
REL=jellyfish

BOARDS="VIM4 #"

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

TITLE="Ubuntu $REL - $TYPE :: $DST installation for: $BOARD ..."

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

GET="curl -A oowow_downloader -jkL"

TITLE="Ubuntu $REL - $TYPE :: $DST($DEST) installation for: $BOARD ..."


[ "$SRC" ] || \
    SRC=https://dl.khadas.com/.test/vim4-ubuntu-22.04-server-linux-5.4-fenix-1.0.11-220704-develop.img.xz

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

echo "$TITLE - DONE"

blkid $DEST*

sleep 1