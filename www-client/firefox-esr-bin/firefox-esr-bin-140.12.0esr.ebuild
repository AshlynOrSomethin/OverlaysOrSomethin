EAPI=8
inherit xdg-utils

DESCRIPTION="Mozilla Firefox ESR (AudioStreamPatcher binary .deb)"
HOMEPAGE="https://github.com/AshlynOrSomethin/AudioStreamPatcher"
SRC_URI="
  amd64? ( https://github.com/AshlynOrSomethin/AudioStreamPatcher/releases/download/browsers-latest/firefox-esr-patched-${PV}-amd64.deb -> ${P}_amd64.deb )
"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

S="${WORKDIR}"
QA_PREBUILT="*"

RDEPEND="
  !www-client/firefox
  !www-client/firefox-bin
"

src_unpack() {
  ar x "${DISTDIR}/${P}_amd64.deb" || die

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
  if [[ -d usr ]]; then
    cp -a usr "${D}"/ || die
  fi
  if [[ -d opt ]]; then
    cp -a opt "${D}"/ || die
  fi

  if [[ -f ${D}/usr/bin/firefox ]]; then
    rm -f "${D}/usr/bin/firefox" || die
  fi

  if [[ -f ${D}/usr/share/applications/firefox.desktop ]]; then
    sed -i \
      -e 's|^Exec=.*|Exec=/usr/bin/firefox-esr %u|' \
      -e 's|^Icon=.*|Icon=firefox|' \
      "${D}/usr/share/applications/firefox.desktop" || die
    mv "${D}/usr/share/applications/firefox.desktop" "${D}/usr/share/applications/firefox-esr.desktop" || die
  fi

  if [[ -x ${D}/opt/firefox/firefox ]]; then
    dosym /opt/firefox/firefox /usr/bin/firefox-esr
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
