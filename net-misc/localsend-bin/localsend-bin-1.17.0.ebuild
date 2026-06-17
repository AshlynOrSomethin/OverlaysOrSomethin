EAPI=8

inherit xdg-utils

DESCRIPTION="LocalSend cross-platform local file sharing app (binary)"
HOMEPAGE="https://github.com/localsend/localsend"
SRC_URI="amd64? ( https://github.com/localsend/localsend/releases/download/v${PV}/LocalSend-${PV}-linux-x86-64.deb -> ${P}.deb )"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

RDEPEND="
  sys-fs/fuse:0
  x11-misc/xdg-user-dirs
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
  if [[ -d usr ]]; then
    cp -a usr "${D}"/ || die
  fi

  if [[ -d ${D}/usr/share/localsend_app ]]; then
    mkdir -p "${D}/opt/localsend-bin" || die
    cp -a "${D}/usr/share/localsend_app/." "${D}/opt/localsend-bin/" || die
    rm -rf "${D}/usr/share/localsend_app"
  fi

  if [[ -f ${D}/opt/localsend-bin/localsend_app ]]; then
    mv "${D}/opt/localsend-bin/localsend_app" "${D}/opt/localsend-bin/localsend" || die
  fi

  if [[ -f ${D}/usr/share/applications/localsend_app.desktop ]]; then
    sed -i -E \
      -e 's|Exec=localsend_app|Exec=localsend|' \
      -e 's|^Icon=.*|Icon=localsend|' \
      "${D}/usr/share/applications/localsend_app.desktop" || die
    mv "${D}/usr/share/applications/localsend_app.desktop" "${D}/usr/share/applications/localsend.desktop" || die
  fi

  for res in 128x128 256x256; do
    if [[ -f ${D}/usr/share/icons/hicolor/${res}/apps/localsend_app.png ]]; then
      mv "${D}/usr/share/icons/hicolor/${res}/apps/localsend_app.png" "${D}/usr/share/icons/hicolor/${res}/apps/localsend.png" || die
    fi
  done

  if [[ ! -e ${D}/usr/bin/localsend ]]; then
    dosym /opt/localsend-bin/localsend /usr/bin/localsend
  fi

  # Ensure the bundled binary is executable.
  if [[ -f ${D}/opt/localsend-bin/localsend ]]; then
    chmod 0755 "${D}/opt/localsend-bin/localsend" || die
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
