#!/bin/bash
# scroll.sh -- run a command and marquee its output into a file.
#
# Port of the waybar custom-module scroll script to dwm: dwm's bar only
# displays the root window name as plain text (no JSON protocol, tooltips
# or CSS classes), so this writes just the current frame to OUTPUT_FILE
# and leaves rendering to the status bar. statusbar.sh can consume it with
# e.g.   track: $(cat /tmp/scroll.txt)
# in its xsetroot line (statusbar.sh itself is NOT modified by this script).
# Original script: https://www.reddit.com/r/unixporn/comments/1xbkb5v/comment/19rfjspoj92ma/
#
# Frames are written atomically (write to tmp + mv) so readers never see a
# half-written frame. COMMAND is re-run every frame; when its output
# changes, the scroll position resets to the start. Command output is
# squashed onto a single line before scrolling.
#
# Usage: scroll.sh [-o OUTPUT_FILE] [-l MAX_LENGTH] [-i INTERVAL]
#                  [-p END_PAUSE] -- COMMAND [ARGS...]
#
#   -o  file to write frames to  (default: /tmp/scroll.txt)
#   -l  visible window width, in characters (default: 24)
#   -i  seconds between frames    (default: 0.2)
#   -p  dwell time at both ends   (default: 2) -- during the dwell the
#       content is not re-checked until the pause ends, like the original
#   -h  this help
#
# Example (spawn from start-dwm, next to the status bar):
#   scroll.sh -- mpc current &
#
# Note: width counts bash characters, not terminal cells, so wide glyphs
# (e.g. CJK) occupy two cells but count as one character.
#
# NOTE: like the rest of bin/*, this gets installed to /usr/bin by the
# PKGBUILD; run it from the repo or rebuild/reinstall the package.

OUTPUT_FILE=/tmp/scroll.txt
MAX_LENGTH=24
INTERVAL=0.2
END_PAUSE=2

usage() {
    sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \{0,1\}//; /^$/d'
    exit 0
}

die() { echo "scroll.sh: $* (see -h)" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        -o) OUTPUT_FILE=${2:?-o needs an argument}; shift 2 ;;
        -l) MAX_LENGTH=${2:?-l needs an argument}; shift 2 ;;
        -i) INTERVAL=${2:?-i needs an argument}; shift 2 ;;
        -p) END_PAUSE=${2:?-p needs an argument}; shift 2 ;;
        -h|--help) usage ;;
        --) shift; break ;;
        *) die "unexpected argument '$1' (put the command after '--')" ;;
    esac
done
[ $# -ge 1 ] || die "no command given"
CMD=("$@")

[[ $MAX_LENGTH =~ ^[0-9]+$ ]] && (( MAX_LENGTH > 0 )) || die "-l must be a positive integer"
[[ $INTERVAL   =~ ^[0-9]+([.][0-9]+)?$ ]]          || die "-i must be a non-negative number"
[[ $END_PAUSE  =~ ^[0-9]+([.][0-9]+)?$ ]]          || die "-p must be a non-negative number"

TMP="${OUTPUT_FILE}.tmp.$$"
# handler must exit explicitly: a trapped SIGTERM does not kill bash otherwise
trap 'rm -f "$TMP"; exit 0' INT TERM
trap 'rm -f "$TMP"' EXIT

get_label() {
    "${CMD[@]}" 2>/dev/null | tr '\n\t' '  ' | sed -e 's/  */ /g' -e 's/^ //' -e 's/ *$//'
}

write_frame() {
    printf '%s\n' "$1" > "$TMP" && mv -f "$TMP" "$OUTPUT_FILE"
}

i=0
step=1
prev_label=
while :; do
    label=$(get_label)

    if [ "$label" != "$prev_label" ]; then
        prev_label=$label
        i=0
        step=1
    fi

    len=${#label}
    if (( len <= MAX_LENGTH )); then
        write_frame "$label"
        i=0
    else
        write_frame "${label:i:MAX_LENGTH}"
        if (( i == len - MAX_LENGTH )); then
            sleep "$END_PAUSE"
            step=-1
        elif (( i == 0 )); then
            sleep "$END_PAUSE"
            step=1
        fi
        i=$(( i + step ))
    fi

    sleep "$INTERVAL"
done
