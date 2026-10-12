# screenshot-common.sh -- shared capture flow for screenshot.sh and
# catboxscreenshot.sh. Source it, then run:
#   screenshot_run "$@" || exit 1
#   [ -z "$FILE" ] && exit 0
# screenshot_run picks full/area via dmenu and captures to $FILE.
# Empty $FILE means the user aborted. Non-zero exit means capture failed.
_libfile=dmenu-theme.sh
_libdir=$(dirname "$0")/../lib
[ -f "$_libdir/$_libfile" ] || _libdir=/usr/share/dwm-scripts
# shellcheck disable=SC1091
. "$_libdir/$_libfile"
unset _libfile _libdir

# unclutter hides the cursor after an idle second and only unhides it when
# it sees pointer motion. During scrot's selection grab all motion goes to
# scrot, so unclutter never unhides (and can even hide mid-selection).
# Freeze it with the cursor visible while selecting.
unclutter_freeze() {
    pgrep -x unclutter > /dev/null 2>&1 || return 0
    if command -v xdotool > /dev/null 2>&1; then
        xdotool mousemove_relative -- 15 0 mousemove_relative -- -15 0 2>/dev/null
        sleep 0.2
    fi
    pkill -STOP -x unclutter 2>/dev/null
    trap 'pkill -CONT -x unclutter 2>/dev/null' EXIT
}

unclutter_thaw() {
    pkill -CONT -x unclutter 2>/dev/null
    trap - EXIT
}

screenshot_run() {
    dmenu_theme_parse "$@"; shift "$DMENU_SHIFT"

    TARGET_DIR="$HOME/screenshots"
    TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
    FILE="$TARGET_DIR/${TIMESTAMP}.png"
    mkdir -p "$TARGET_DIR"

    MODE=$(echo -e "full screen\nselect area" | dmenu -l 2 -fn "$DMENU_FN" -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF" -p "screenshot type:" -vi -bw 2 -c)
    case "$MODE" in
        "full screen")
            ARG=""
            ;;
        "select area")
            ARG="-s -f -z"
            ;;
        *)
            FILE=""
            return 0
            ;;
    esac

    sleep 0.25

    [ -n "$ARG" ] && unclutter_freeze
    # shellcheck disable=SC2086
    if scrot $ARG "$FILE"; then
        rc=0
    else
        echo "Failed to capture screenshot."
        rc=1
    fi
    [ -n "$ARG" ] && unclutter_thaw
    return $rc
}
