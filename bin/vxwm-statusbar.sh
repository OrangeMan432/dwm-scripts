#!/bin/bash
echo $$ > /tmp/statusbar.pid

power () {
	grep -q "1" /sys/class/power_supply/AC/online && psu=" (on power)" || psu=" (on battery)"
	echo "$(cat /sys/class/power_supply/BAT0/capacity)%$psu"
}

internet () {
	#local status=$(mullvad status | awk '/Relay:/ {print $2 " " $3 " " $4}')
	local status=$(mullvad status | awk '/Relay:/ {for (i=2; i<=NF; i++) printf "%s%s", $i, (i==NF ? "" : " ")}')

	if [ -f /sys/class/net/eth0/carrier ] && [ "$(cat /sys/class/net/eth0/carrier)" -eq 1 ]; then
		echo "ethernet"
		return
	fi

	[ -z "$status" ] && status=$(iwgetid -r)

	echo "${status:-offline}"
}

volume () {
	echo $(pamixer --get-volume-human)
}

time_ () {
	echo $(date +%r)
}

while true; do
	xsetroot -name " time: $(time_),  battery: $(power),  volume: $(volume) "
	sleep 1
done
