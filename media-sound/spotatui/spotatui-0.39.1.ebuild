EAPI=8
inherit xdg-utils

DESCRIPTION="spotatui - a terminal Spotify client (binary, installed from upstream .deb)"
HOMEPAGE="https://github.com/LargeModGames/spotatui"
SRC_URI="
  amd64? ( https://github.com/LargeModGames/spotatui/releases/download/v${PV}/spotatui_${PV}-1_amd64.deb -> ${P}_amd64.deb )
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="mirror strip"

S="${WORKDIR}"
QA_PREBUILT="*"

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
  [[ -d usr ]] && cp -a usr "${D}"/ || die
  [[ -d opt ]] && cp -a opt "${D}"/ || die

  if [[ -f ${D}/usr/share/applications/spotatui.desktop ]]; then
    sed -i \
      -e 's|^Exec=.*|Exec=/usr/bin/spotatui|' \
      -e 's|^Icon=.*|Icon=spotatui|' \
      "${D}/usr/share/applications/spotatui.desktop" || die
  fi

  if [[ ! -x ${D}/usr/bin/spotatui && -x ${D}/opt/spotatui/spotatui ]]; then
    dosym /opt/spotatui/spotatui /usr/bin/spotatui
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
