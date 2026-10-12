#!/bin/bash
# screenshot.sh -- capture, copy the image to the clipboard, notify.
# Themed via argv (-fn/-nb/-nf/-sb/-sf), DMENU_* env, or dmenu-theme defaults.
_libfile=screenshot-common.sh
_libdir=$(dirname "$0")/../lib
[ -f "$_libdir/$_libfile" ] || _libdir=/usr/share/dwm-scripts
# shellcheck disable=SC1091
. "$_libdir/$_libfile"
unset _libfile _libdir
screenshot_run "$@" || exit 1
[ -z "$FILE" ] && exit 0

if xclip -selection clipboard -target image/png -i "$FILE"; then
    notify-send "Screenshot taken."
else
    echo "Failed to copy screenshot to clipboard."
    exit 1
fi
