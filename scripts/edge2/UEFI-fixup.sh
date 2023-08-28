#!/bin/sh

## hyphop ##

#= UEFI-fix-up

DESCRIPTION="\
UEFI fix-up
===========

Update eMMC bootloader to UEFI

DL:      https://dl.khadas.com/products/edge2/firmware/UEFI/
Sources: https://github.com/edk2-porting/edk2-rk3588
Actual:  https://github.com/edk2-porting/edk2-rk3588/suites/15541896185/artifacts/886911610
Docs:    https://docs.khadas.com/products/sbc/edge2/troubleshooting/edge2-uboot-uefi

    BOARDS= Edge2
      NEED= Network
" #DESCRIPTION_END

LABEL="UEFI"
BOARDS="Edge2 "

#REL=${REL:-v0.7.1}
#SRC=${SRC:-edge2_UEFI_Release_$REL.img}
#BASE=https://github.com/edk2-porting/edk2-rk3588/releases/download

REL=${REL:-dbaeeac}
SRC=${SRC:-edge2-uefi-release-$REL.img}
BASE=https://dl.khadas.com/products/edge2/firmware/UEFI/

IMG="/tmp/$SRC"
DL=${DL:-$BASE/$REL/$SRC}

TITLE="$BOARD fix-up UEFI"

set -e -o pipefail

[ "$BOARD" ] || \
BOARD=$(board_name 2>/dev/null || echo Undefined)

[ "$DST" ] || \
DST=$(mmc_disk 2>/dev/null || echo /dev/null)

FAIL(){
[ "$GUI" ] && {
dialog --title "Error" \
    --no-collapse \
    --msgbox " $@ " \
    0 0
exit 1
}

echo "[e] $@">&2
exit 1
}

CMD(){
echo "# $@">&2
"$@"
}

GUI_SEL=/tmp/gui_sel

echo "$BOARDS" | grep -q -m1 "$BOARD" || FAIL "Not suitable for $BOARD device"

echo "$TITLE +$TYPE > $DST"
echo "DL $DL"

MSG="Are u ready fixup/update UEFI bootloader

REL : $REL
FROM: $BASE
SRC : $SRC
TO  : $DST
----------
WARN: $((0x4000))-$((0x8000)) blocks on $DST must be used for UEFI
----------
"

dialog --title "$TITLE" \
    --no-collapse \
    --yesno "$MSG" \
    0 0 2>$GUI_SEL || exit

DL(){
    [ -s $IMG.checked ] && return 0
    CMD curl -A downloader -jkL "$@" || return 1
    md5sum $IMG > $IMG.checked
}

DL $DL -o $IMG || FAIL "Download $DL"

#COUNT=${COUNT:-0x4000} # max size nvme override
COUNT=${COUNT:-0x3600} # printf %X $((0x6c0000/512)) do not nvme override

CMD dd skip=2048 seek=$((0x4000)) \
    count=$(($COUNT)) of=$DST if=$IMG conv=fsync,notrunc || FAIL "Fail update $SRC to $DST error: $?"

dialog --title "Done" \
    --no-collapse \
    --msgbox "
UEFI bootloader was updated to $SRC
" \
    0 0

exit 0

## __END__

<<END

Links

    https://opensource.rock-chips.com/wiki_Boot_option
    https://opensource.rock-chips.com/wiki_U-Boot
    https://github.com/edk2-porting/edk2-rk35xx/releases

