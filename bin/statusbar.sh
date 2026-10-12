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

    [ -z "$status" ] && status=$(iwgetid -r)

    echo "${status:-offline}"
}

uptime_ () {
    echo $(uptime | sed 's/^ *[^ ]* //')
}

volume () {
    echo $(pamixer --get-volume)
}

music () {
    metadata=$(playerctl metadata --format '{{ title }} - {{ artist }}' 2>/dev/null)
    status=$(playerctl status)

    if [[ -n "$metadata" ]]; then
        echo ",  track: ${metadata} (${status})"
    fi
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

while true; do
    xsetroot -name " $(date)$(kernel) ; $(uptime_),  internet: $(internet),  battery: $(power),  volume: $(volume)$(music)"
    sleep 1
done
