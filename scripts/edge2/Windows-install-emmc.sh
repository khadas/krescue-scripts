#!/bin/sh

## hyphop ##

#= UEFI-fix-up

DESCRIPTION="\
Windows install eMMC
====================

    BOARDS= Edge2
      NEED= Network

" #DESCRIPTION_END

LABEL="Windows"
BOARDS="Edge2 "

REL=arm
SRC=${SRC:-edge2-windows-11-$REL.img.zst}
BASE=https://dl.khadas.com/products/edge2/firmware/.windows

DL=${DL:-$BASE/$SRC}

TITLE="$BOARD Windows 11 install to eMMC"

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

MSG="Are u ready install Windows 11 to eMMC

FROM : $DL
TO   : $DST
----------
WARN: All stored data on eMMC will be lost !!!
      Installation need stable internet connection !!!
----------
TIP:  During windows setup
      Shift+F10 type oobe\bypassnro press Enter to
             reboot and skip network request

"

dialog --title "$TITLE" \
    --no-collapse \
    --yesno "$MSG" \
    0 0 2>$GUI_SEL || exit

echo "[i] Download $DL write> $DST"
echo "[i] WAIT .... its can be long"
curl -f -jkL $DL | zstd -dc > $DST || {

sleep 2
dialog --title "Error" \
    --no-collapse \
    --msgbox "
Installation was failed... Please try again...
" \
    0 0

exit 1

}

dialog --title "Done" \
    --no-collapse \
    --msgbox "
Windows installation was done, can reboot...
" \
    0 0

exit 0

## __END__

<<END

Links
