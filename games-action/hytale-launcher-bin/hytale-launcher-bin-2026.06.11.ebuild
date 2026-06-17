EAPI=8

inherit xdg-utils

DESCRIPTION="Hytale Launcher (Native Linux, self-updating)"
HOMEPAGE="https://hytale.com"
MY_PV_FULL="${PV}-00b733c"
SRC_URI="amd64? ( https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-${MY_PV_FULL}.zip -> ${P}-${MY_PV_FULL}.zip )"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror bindist"

RDEPEND="
  net-libs/webkit-gtk:4.1
  x11-libs/gtk+:3
  x11-themes/hicolor-icon-theme
  net-libs/libsoup:3.0
  x11-libs/gdk-pixbuf:2
"

S="${WORKDIR}"
QA_PREBUILT="*"

src_install() {
  exeinto /opt/${PN}
  doexe hytale-launcher || die

  if [[ -f icon.png ]]; then
    insinto /usr/share/icons/hicolor/256x256/apps
    newins icon.png com.hypixel.HytaleLauncher.png
  fi

  cat > "${T}/hytale-launcher" <<'EOF' || die
#!/bin/sh

# Wayland sessions may not export DISPLAY; detect active X server.
if [ -z "${DISPLAY}" ] && command -v pgrep >/dev/null 2>&1; then
  for xproc in Xwayland Xorg; do
    xpid=$(pgrep -u "$(id -u)" -n "${xproc}" 2>/dev/null || true)
    if [ -n "${xpid}" ] && [ -r "/proc/${xpid}/cmdline" ]; then
      xargs=$(tr '\0' ' ' < "/proc/${xpid}/cmdline")
      set -- ${xargs}
      for arg in "$@"; do
        case "${arg}" in
          :[0-9]*)
            export DISPLAY="${arg}"
            break
            ;;
        esac
      done
    fi
    [ -n "${DISPLAY}" ] && break
  done
fi

exec /opt/hytale-launcher-bin/hytale-launcher "$@"
EOF
  dobin "${T}/hytale-launcher"

  cat > "${T}/com.hypixel.HytaleLauncher.desktop" <<'EOF' || die
[Desktop Entry]
Name=Hytale Launcher
Comment=Hytale Launcher
Exec=/usr/bin/hytale-launcher
Icon=com.hypixel.HytaleLauncher
Terminal=false
Type=Application
Categories=Game;
StartupWMClass=com.hypixel.HytaleLauncher
EOF
  insinto /usr/share/applications
  doins "${T}/com.hypixel.HytaleLauncher.desktop"

  if [[ -f LICENSE ]]; then
    insinto /usr/share/licenses/${PF}
    newins LICENSE LICENSE
  fi
}

pkg_postinst() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  type xdg_icon_cache_update >/dev/null 2>&1 && xdg_icon_cache_update
  type update_icon_caches >/dev/null 2>&1 && update_icon_caches
}

pkg_postrm() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  type xdg_icon_cache_update >/dev/null 2>&1 && xdg_icon_cache_update
  type update_icon_caches >/dev/null 2>&1 && update_icon_caches
}
