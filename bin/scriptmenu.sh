#!/bin/bash
# scriptmenu.sh -- dmenu picker behind the menu key: choose a script, run it.
# Add new entries to the list below and the case statement.
# Themed via argv (-fn/-nb/-nf/-sb/-sf), DMENU_* env, or dmenu-theme defaults.
_libfile=dmenu-theme.sh
_libdir=$(dirname "$0")/../lib
[ -f "$_libdir/$_libfile" ] || _libdir=/usr/share/dwm-scripts
# shellcheck disable=SC1091
. "$_libdir/$_libfile"
unset _libfile _libdir
dmenu_theme_parse "$@"; shift "$DMENU_SHIFT"
# export so children launched via a terminal (e.g. wifi.sh under st)
# inherit the theme; direct children also get it as argv below.
export DMENU_FN DMENU_NB DMENU_NF DMENU_SB DMENU_SF

theme=(-fn "$DMENU_FN" -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF")

choice=$(printf '%s\n' "screenshot" "upload screenshot" "wifi" | dmenu "${theme[@]}" -p "run:" -l 5 -vi -bw 2 -c)

case "$choice" in
    screenshot)
        /usr/bin/screenshot.sh "${theme[@]}" &
        ;;
    "upload screenshot")
        /usr/bin/catboxscreenshot.sh "${theme[@]}" &
        ;;
    wifi)
        # needs a terminal: sudo may prompt and output should stay visible
        st -e sh -c "/usr/bin/wifi.sh; printf '\n-- press enter to close -- '; read _" &
        ;;
esac
