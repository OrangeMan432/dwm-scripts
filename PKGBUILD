pkgname=dwm-scripts
pkgver=1.0
pkgrel=1
pkgdesc="dmenu screenshot/wifi/menu helpers for dwm"
arch=('any')
license=('MIT')
depends=('scrot' 'xclip' 'xorg-xsetroot' 'libnotify' 'sudo' 'xdotool'
         'iw' 'wpa_supplicant' 'dhcpcd'
         'pamixer' 'playerctl' 'wireless_tools'
         'catbox-bin')
optdepends=('unclutter: cursor handling during area selection'
            'mullvad-vpn-beta-bin: vpn segment in statusbar (paid)')
# NOTE: dmenu, st, slock and tabbed are NOT listed here -- they come from
# source builds in ~/repos, not from pacman.
# NOTE: sources are copied from $startdir (local-only package, nothing to
# download -- makepkg does not support subdirectories in source entries).
source=()
md5sums=()

package() {
  install -Dm755 -t "$pkgdir/usr/bin/" "$startdir"/bin/*
  install -Dm644 -t "$pkgdir/usr/share/dwm-scripts/" "$startdir"/lib/*
}
