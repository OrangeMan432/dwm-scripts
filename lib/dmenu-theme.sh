# dmenu-theme.sh -- shared dmenu colorscheme for dwm-scripts.
#
# Sourcing scripts get five variables: DMENU_FN, DMENU_NB, DMENU_NF,
# DMENU_SB, DMENU_SF. Precedence:
#   1. command-line flags: -fn/-nb/-nf/-sb/-sf
#   2. environment: DMENU_FN/DMENU_NB/DMENU_NF/DMENU_SB/DMENU_SF
#   3. built-in defaults below (mirror dwm's colors.h, gruvbox material).
#
# Usage at the top of a script:
#   _libfile=dmenu-theme.sh
#   _libdir=$(dirname "$0")/../lib
#   [ -f "$_libdir/$_libfile" ] || _libdir=/usr/share/dwm-scripts
#   # shellcheck disable=SC1091
#   . "$_libdir/$_libfile"
#   unset _libfile _libdir
#   dmenu_theme_parse "$@"; shift "$DMENU_SHIFT"
#
# Then theme the dmenu call:
#   ... | dmenu -fn "$DMENU_FN" -nb "$DMENU_NB" -nf "$DMENU_NF" \
#       -sb "$DMENU_SB" -sf "$DMENU_SF" -p "prompt:" ...
#
# To keep a script's own look by default, preset variables before sourcing,
# e.g.: DMENU_FN="${DMENU_FN:-JetBrainsMono Nerd Font:size=10}"
#
# dwm's config.h passes the colorscheme from keybinds, e.g.:
#   static const char *screenshotcmd[] = {
#       "/usr/bin/screenshot.sh",
#       "-nb", col_gray1, "-nf", col_fg1, "-sb", col_bg2, "-sf", col_fg1,
#       "-fn", dmenufont, NULL };

# Built-in defaults mirror dwm's colors.h.
: "${DMENU_FN:=JetBrainsMono Nerd Font:size=16}"
: "${DMENU_NB:=#111111}"
: "${DMENU_NF:=#ddc7a1}"
: "${DMENU_SB:=#282828}"
: "${DMENU_SF:=#ddc7a1}"

# dmenu_theme_parse: consume leading -fn/-nb/-nf/-sb/-sf flags from "$@".
# Sets DMENU_SHIFT to the number of consumed arguments so callers can
# `shift "$DMENU_SHIFT"` to leave their own positional args intact
# (e.g. the password prompt sudo passes to dmenu-askpass.sh).
dmenu_theme_parse() {
    DMENU_SHIFT=0
    while [ $# -gt 0 ]; do
        case "$1" in
            -fn) DMENU_FN="$2"; shift 2; DMENU_SHIFT=$((DMENU_SHIFT + 2)) ;;
            -nb) DMENU_NB="$2"; shift 2; DMENU_SHIFT=$((DMENU_SHIFT + 2)) ;;
            -nf) DMENU_NF="$2"; shift 2; DMENU_SHIFT=$((DMENU_SHIFT + 2)) ;;
            -sb) DMENU_SB="$2"; shift 2; DMENU_SHIFT=$((DMENU_SHIFT + 2)) ;;
            -sf) DMENU_SF="$2"; shift 2; DMENU_SHIFT=$((DMENU_SHIFT + 2)) ;;
            *) break ;;
        esac
    done
}
