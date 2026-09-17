EAPI=8
inherit desktop xdg-utils

DESCRIPTION="Equibop (binary, installed from upstream .deb)"
HOMEPAGE="https://github.com/Equicord/Equibop"
SRC_URI="
  amd64? ( https://github.com/Equicord/Equibop/releases/download/v${PV}/equibop_${PV}_amd64.deb -> ${P}_amd64.deb )
"

LICENSE="GPL-3"
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
  if [[ -d usr ]]; then
    cp -a usr "${D}"/ || die
  fi
  if [[ -d opt ]]; then
    cp -a opt "${D}"/ || die
  fi

  if [[ -f ${D}/usr/share/applications/equibop.desktop ]]; then
    sed -i \
      -e 's|^Exec=.*|Exec=/usr/bin/equibop %U|' \
      -e 's|^Icon=.*|Icon=equibop|' \
      "${D}/usr/share/applications/equibop.desktop" || die
  fi

  if [[ ! -x ${D}/usr/bin/equibop ]]; then
    if [[ -x ${D}/opt/Equibop/equibop ]]; then
      dosym /opt/Equibop/equibop /usr/bin/equibop
    elif [[ -x ${D}/opt/equibop/equibop ]]; then
      dosym /opt/equibop/equibop /usr/bin/equibop
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
