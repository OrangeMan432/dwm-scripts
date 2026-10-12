#!/bin/bash
# catboxscreenshot.sh -- capture, upload to catbox, copy the URL to the clipboard.
# Themed via argv (-fn/-nb/-nf/-sb/-sf), DMENU_* env, or dmenu-theme defaults.
_libfile=screenshot-common.sh
_libdir=$(dirname "$0")/../lib
[ -f "$_libdir/$_libfile" ] || _libdir=/usr/share/dwm-scripts
# shellcheck disable=SC1091
. "$_libdir/$_libfile"
unset _libfile _libdir
screenshot_run "$@" || exit 1
[ -z "$FILE" ] && exit 0

# Catbox account hash. Set CATBOX_USER_HASH in the environment or store it
# in ~/.config/dwm-scripts/catbox-hash (chmod 600). Never commit it.
if [ -z "${CATBOX_USER_HASH:-}" ]; then
    CATBOX_USER_HASH=$(cat "$HOME/.config/dwm-scripts/catbox-hash" 2>/dev/null)
fi
if [ -z "$CATBOX_USER_HASH" ]; then
    echo "CATBOX_USER_HASH is not set and ~/.config/dwm-scripts/catbox-hash is missing."
    notify-send "Screenshot upload failed: no catbox hash configured."
    exit 1
fi
URL=$(catbox --user "$CATBOX_USER_HASH" upload "$FILE")
case "$URL" in
    https://*)
        notify-send "Upload successful: $URL"
        echo -n "$URL" | xclip -selection clipboard
        ;;
    *)
        notify-send "Screenshot upload failed."
        exit 1
        ;;
esac
