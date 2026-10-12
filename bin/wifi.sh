#!/bin/bash
# wifi.sh -- pick a nearby network from dmenu and connect with
# wpa_supplicant + dhcpcd. Meant to run in a terminal (shows progress).
# sudo authenticates via dmenu (SUDO_ASKPASS), so no terminal password
# prompt is needed. Themed via argv, DMENU_* env, or dmenu-theme defaults.
_libfile=dmenu-theme.sh
_libdir=$(dirname "$0")/../lib
[ -f "$_libdir/$_libfile" ] || _libdir=/usr/share/dwm-scripts
# shellcheck disable=SC1091
. "$_libdir/$_libfile"
unset _libfile _libdir
dmenu_theme_parse "$@"; shift "$DMENU_SHIFT"

IFACE="${1:-wlan0}"
CONF="/tmp/wpa-${IFACE}.conf"

export SUDO_ASKPASS="/usr/bin/dmenu-askpass.sh"

echo "== unblocking wifi =="
rfkill unblock wlan
sudo -A ip link set "$IFACE" up

echo "== authenticating sudo (dmenu password prompt) =="
sudo -A -v

echo "== dropping stale connection on $IFACE (frees the radio) =="
sudo -A pkill -f "wpa_supplicant.*$IFACE" 2>/dev/null
sudo -A dhcpcd -k "$IFACE" 2>/dev/null
sleep 1

parse_scan() {
    sudo -A iw dev "$IFACE" scan dump 2>/dev/null | awk '
        /^BSS / { sig = "" }
        /signal:/ { sig = $2 }
        /SSID:/ {
            ssid = $0
            sub(/^.*SSID: /, "", ssid)
            if (ssid != "" && !(ssid in seen)) {
                seen[ssid] = sig
                print sig, ssid
            }
        }' | sort -rn | cut -d' ' -f2-
}

echo "== triggering scan on $IFACE =="
sudo -A iw dev "$IFACE" scan > /dev/null 2>&1
sleep 5
mapfile -t NETWORKS < <(parse_scan)

if [ "${#NETWORKS[@]}" -eq 0 ]; then
    echo "first scan came back empty, waiting 5 more seconds and retrying..."
    sleep 5
    mapfile -t NETWORKS < <(parse_scan)
fi

if [ "${#NETWORKS[@]}" -eq 0 ]; then
    echo "no networks found."
    exit 1
fi

echo "== nearby networks (strongest first) =="
printf '  %s\n' "${NETWORKS[@]}"

SSID=$(printf '%s\n' "${NETWORKS[@]}" | dmenu -fn "$DMENU_FN" -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF" -p "network:" -l 10 -vi -bw 2 -c)
if [ -z "$SSID" ]; then
    echo "no network selected, aborting."
    exit 1
fi
echo "selected: $SSID"

current=$(iw dev "$IFACE" link 2>/dev/null | awk '/SSID:/ { sub(/^.*SSID: /, ""); print }')
if [ "$current" = "$SSID" ]; then
    echo "already connected to $SSID."
    exit 0
fi

PSK=$(dmenu -fn "$DMENU_FN" -nb "$DMENU_NB" -nf "$DMENU_NF" -sb "$DMENU_SB" -sf "$DMENU_SF" -p "password for '$SSID' (empty = open):" -l 1 -vi -bw 2 -c -P < /dev/null)
if [ $? -ne 0 ]; then
    echo "aborted."
    exit 1
fi

echo "== writing $CONF =="
if [ -z "$PSK" ]; then
    printf 'network={\n\tssid="%s"\n\tkey_mgmt=NONE\n}\n' "$SSID" | sudo -A tee "$CONF" > /dev/null
else
    wpa_passphrase "$SSID" "$PSK" | sudo -A tee "$CONF" > /dev/null
fi
unset PSK
sudo -A chmod 600 "$CONF"

echo "== connecting =="
sudo -A wpa_supplicant -B -i "$IFACE" -c "$CONF"
sudo -A dhcpcd "$IFACE"

echo "== status =="
iw dev "$IFACE" link
ip -brief addr show "$IFACE"
