EAPI=8
inherit xdg-utils

DESCRIPTION="Fresh Editor (binary, installed from upstream .deb)"
HOMEPAGE="https://sinelaw.github.io/fresh/ https://github.com/sinelaw/fresh"
SRC_URI="
  amd64? ( https://github.com/sinelaw/fresh/releases/download/v${PV}/fresh-editor_${PV}-1_amd64.deb -> ${P}_amd64.deb )
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

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

  if [[ -f ${D}/usr/share/applications/fresh-editor.desktop ]]; then
    sed -i \
      -e 's|^Exec=.*|Exec=/usr/bin/fresh-editor %U|' \
      -e 's|^Icon=.*|Icon=fresh-editor|' \
      "${D}/usr/share/applications/fresh-editor.desktop" || die
  fi

  if [[ ! -x ${D}/usr/bin/fresh-editor ]]; then
    if [[ -x ${D}/usr/bin/fresh ]]; then
      dosym /usr/bin/fresh /usr/bin/fresh-editor
    elif [[ -x ${D}/opt/fresh-editor/fresh-editor ]]; then
      dosym /opt/fresh-editor/fresh-editor /usr/bin/fresh-editor
    elif [[ -x ${D}/opt/fresh-editor/fresh ]]; then
      dosym /opt/fresh-editor/fresh /usr/bin/fresh-editor
    fi
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
