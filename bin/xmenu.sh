#!/bin/sh
# xmenu.sh -- right-click application menu (spawned from start-dwm).
export SUDO_ASKPASS="/usr/bin/dmenu-askpass.sh"

steam_games=$(find ~/.steam/steam/steamapps/ -maxdepth 1 -type f -name '*.acf' \
    -exec awk -F '"' '/"appid|name/{ printf $4 "|" } END { print "" }' {} \; | \
    grep -iv "Steam Linux Runtime" | \
    awk -F '|' '{ print "\t\t" $2 "\tsteam steam://rungameid/" $1 }' | sort)

xmenu <<EOF | sh &
Applications
	Web Browser	librewolf
	Internet Chat	st concord
	Image Editor	gimp
	Text Editor	st vim
	File Manager	thunar
	Task Manager	st btm
	Terminal	st
Games
	Minecraft	prismlauncher
	Steam Games
$steam_games
	Steam		steam
Scripts
	Take Screenshot	/usr/bin/screenshot.sh

Power
	Log out		killall start-vxwm & killall start-dwm & killall start-xfwm4 & killall statusbar.sh
	Lock Screen	slock
	Power Off	sudo -A poweroff
	Reboot		sudo -A reboot
EOF
