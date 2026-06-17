EAPI=8

inherit xdg-utils

DESCRIPTION="MQTT Explorer binary package"
HOMEPAGE="https://github.com/thomasnordquist/MQTT-Explorer"
MY_PV="${PV/_/-}"
SRC_URI="amd64? ( https://github.com/thomasnordquist/MQTT-Explorer/releases/download/v${MY_PV}/MQTT-Explorer_${MY_PV}_amd64.deb -> ${P}.deb )"

LICENSE="CC-BY-ND-4.0"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

RDEPEND="
  dev-libs/nspr
  dev-libs/nss
  x11-libs/gtk+:3
  media-libs/alsa-lib
"

S="${WORKDIR}"
QA_PREBUILT="*"

src_unpack() {
  ar x "${DISTDIR}/${P}.deb" || die

  local tarball=
  for tarball in data.tar.zst data.tar.xz data.tar.gz; do
    if [[ -f ${tarball} ]]; then
      tar xf "${tarball}" || die
      break
    fi
  done

  [[ -n ${tarball} ]] || die "Unsupported .deb payload format"
}

src_install() {
  if [[ -d opt ]]; then
    cp -a opt "${D}"/ || die
  fi
  if [[ -d usr ]]; then
    cp -a usr "${D}"/ || die
  fi

  # Ensure executables in opt are executable.
  if [[ -d ${D}/opt/MQTT\ Explorer/bin ]]; then
    find "${D}/opt/MQTT Explorer/bin" -type f -exec chmod 0755 {} + || die
  fi

  if [[ ! -x ${D}/usr/bin/mqtt-explorer && -x ${D}/opt/MQTT\ Explorer/mqtt-explorer ]]; then
    dosym '/opt/MQTT Explorer/mqtt-explorer' /usr/bin/mqtt-explorer
  fi

  cat > "${T}/mqtt-explorer.desktop" <<'EOF' || die
[Desktop Entry]
Name=MQTT Explorer
Exec=mqtt-explorer
Terminal=false
Type=Application
Icon=mqtt-explorer
StartupWMClass=MQTT Explorer
Comment=Explore your message queues
Categories=Development;
EOF
  insinto /usr/share/applications
  doins "${T}/mqtt-explorer.desktop"
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
