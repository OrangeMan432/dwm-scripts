#!/bin/bash
# statusbar.sh -- feed dwm's status text via xsetroot (spawned from start-dwm).
echo $$ > /tmp/statusbar.pid

power () {
    grep -q "1" /sys/class/power_supply/AC/online && psu=" (on power)" || psu=" (on battery)"
    echo "$(cat /sys/class/power_supply/BAT0/capacity)%$psu"
}

internet () {
    local status=$(mullvad status | awk '/Relay:/ {for (i=2; i<=NF; i++) printf "%s%s", $i, (i==NF ? "" : " ")}')

    if [ -f /sys/class/net/eth0/carrier ] && [ "$(cat /sys/class/net/eth0/carrier)" -eq 1 ]; then
        echo "ethernet"
        return
    fi

    # [ -z "$status" ] && status=$(iwgetid -r)
    [ -z "$status" ] && status="wifi"

    echo "${status:-offline}"
}

uptime_ () {
    echo $(uptime | sed 's/^ *[^ ]* //')
}

volume () {
    echo $(pamixer --get-volume)
}

MARQUEE_LEN=32      # width of the scrolling window, in characters
MARQUEE_HOLD=10     # ticks to dwell at both ends (10 * 0.2s = 2s)
MARQUEE_I=0
MARQUEE_STEP=1
MARQUEE_PREV=
MARQUEE_HOLD_LEFT=0

music () {
	MUSIC_SEG=
	metadata=$(playerctl metadata --format '{{ title }} - {{ artist }}' 2>/dev/null)
	status=$(playerctl status 2>/dev/null)

	[ -z "$status" ] && return # no MPRIS player (or playerctl missing)

	if [ -z "$metadata" ]; then
		printf -v MUSIC_SEG ',  track: (%s)' "$status"
		return
	fi

	if [ "$metadata" != "$MARQUEE_PREV" ]; then
		MARQUEE_PREV=$metadata
		MARQUEE_I=0
		MARQUEE_STEP=1
		MARQUEE_HOLD_LEFT=0
	fi

	len=${#metadata}
	if (( len <= MARQUEE_LEN )); then
		frame=$metadata
		MARQUEE_I=0
	else
		frame=${metadata:MARQUEE_I:MARQUEE_LEN}
		if (( MARQUEE_HOLD_LEFT )); then
			MARQUEE_HOLD_LEFT=$(( MARQUEE_HOLD_LEFT - 1 ))
		else
			MARQUEE_I=$(( MARQUEE_I + MARQUEE_STEP ))
			if (( MARQUEE_I >= len - MARQUEE_LEN )); then
				MARQUEE_I=$(( len - MARQUEE_LEN ))
				MARQUEE_STEP=-1
				MARQUEE_HOLD_LEFT=$MARQUEE_HOLD
			elif (( MARQUEE_I <= 0 )); then
				MARQUEE_I=0
				MARQUEE_STEP=1
				MARQUEE_HOLD_LEFT=$MARQUEE_HOLD
			fi
		fi
	fi

	printf -v MUSIC_SEG ',  track: %s (%s)' "$frame" "$status"
}

kernel () {
    RUNNING_KERNEL=$(uname -r)

    INSTALLED_KERNEL=$(pacman -Q linux 2>/dev/null | awk '{print $2}')

    if [ -z "$INSTALLED_KERNEL" ]; then
        exit 1
    fi

    NORMALIZED_INSTALLED=$(echo "$INSTALLED_KERNEL" | sed 's/\.artix/-artix/')

    if [[ "$RUNNING_KERNEL" == "$NORMALIZED_INSTALLED"* ]]; then
        echo ""
    else
        echo ",  reboot for kernel update!"
    fi
}

# fast segments are recomputed every tick (0.2s); the expensive ones are
# cached and refreshed only every 5th tick (~1s). Volume is deliberately
# recomputed every tick (it is cheap): vxwm's media keys kill this process'
# child `sleep` to make the bar repaint immediately, and that only works if
# the bar re-reads the volume on the very next render. xsetroot is only
# called when the rendered line actually changed, so a static/short track
# doesn't make dwm redraw at 5Hz.
TICK=0
CACHE_INTERNET=$(internet)
CACHE_KERNEL=$(kernel)
CACHE_UPTIME=$(uptime_)
CACHE_POWER=$(power)
CACHE_VOLUME=$(volume)
LAST_NAME=

while true; do
	if (( TICK % 5 == 0 )); then
		CACHE_INTERNET=$(internet)
		CACHE_KERNEL=$(kernel)
		CACHE_UPTIME=$(uptime_)
		CACHE_POWER=$(power)
	fi

	CACHE_VOLUME=$(volume)

	music
	name=" $(date)${CACHE_KERNEL} ; ${CACHE_UPTIME},  internet: ${CACHE_INTERNET},  battery: ${CACHE_POWER},  volume: ${CACHE_VOLUME}${MUSIC_SEG}"

	if [ "$name" != "$LAST_NAME" ]; then
		xsetroot -name "$name"
		LAST_NAME=$name
	fi

	TICK=$(( TICK + 1 ))
	sleep 0.2
done
