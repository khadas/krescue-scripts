#!/bin/bash

## hyphop ##

#= Template-Linux-install

DESCRIPTION="\
DISTRO
======

Descrition
" #DESCRIPTION_END

NAME="${0%-*}"

BOARDS="VIM1 VIM2 VIM3 VIM3L Edge #"

## USAGE examples

## PROBLEMS

set -e -o pipefail

[ "$DST" ] || \
DST=$(mmc_disk 2>/dev/null || echo /dev/null)

FAIL(){
echo "[e] $@">&2
exit 1
}

[ "$BOARD" ] || \
BOARD=$(board_name 2>/dev/null || echo Undefined)

echo "$NAME installation for: $BOARD ... > $DST"
echo "$BOARDS" | grep -q -m1 "$BOARD" || FAIL "not suitable for this $BOARD device"

# checks
# echo "check network connection..."
net_check_default_route 1>/dev/null 2>&1 || \
    FAIL "Please check or setup network connection"
# stop prev session
pkill -f downloader || true
sleep 1

#modules_download_ipk fs
#modprobe xfs || exit 1
#modprobe btrfs || exit 1

## __END__