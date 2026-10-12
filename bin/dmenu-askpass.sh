#!/bin/sh
# dmenu-askpass.sh -- dmenu-based password prompt for sudo -A (SUDO_ASKPASS).
# Themed via argv (-fn/-nb/-nf/-sb/-sf), DMENU_* env, or defaults below.
# NOTE: sudo invokes the askpass helper with only a prompt argument, so a
# dwm keybind cannot pass argv here -- use DMENU_* env (or the defaults).
DMENU_FN="${DMENU_FN:-JetBrainsMono Nerd Font:size=16}"
_libfile=dmenu-theme.sh
_libdir=$(dirname "$0")/../lib
[ -f "$_libdir/$_libfile" ] || _libdir=/usr/share/dwm-scripts
# shellcheck disable=SC1091
. "$_libdir/$_libfile"
unset _libfile _libdir
dmenu_theme_parse "$@"; shift "$DMENU_SHIFT"
dmenu -l 2 -fn "$DMENU_FN" -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF" -p "sudo password:" -vi -bw 2 -c -P
