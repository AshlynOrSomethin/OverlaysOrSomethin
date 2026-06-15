EAPI=8
inherit xdg-utils

DESCRIPTION="Zen Browser (binary AppImage)"
HOMEPAGE="https://github.com/zen-browser/desktop"
SRC_URI="
  amd64? ( https://github.com/zen-browser/desktop/releases/download/${PV}/zen-x86_64.AppImage -> ${P}.AppImage )
"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

S="${WORKDIR}"
QA_PREBUILT="*"

RDEPEND="
  sys-fs/fuse:0
"

src_unpack() {
  :
}

src_prepare() {
  default

  cp "${DISTDIR}/${P}.AppImage" "${S}/${P}.AppImage" || die
  chmod +x "${S}/${P}.AppImage" || die
  "${S}/${P}.AppImage" --appimage-extract || die
}

src_install() {
  exeinto "/opt/${PN}"
  newexe "${P}.AppImage" "zen-browser.AppImage"

  local desktop_file
  desktop_file=$(find squashfs-root -maxdepth 4 -type f -name '*.desktop' | head -n1)
  if [[ -n ${desktop_file} ]]; then
    sed -i \
      -e 's|^Exec=.*|Exec=/usr/bin/zen-browser %U|' \
      -e 's|^Icon=.*|Icon=zen-browser|' \
      "${desktop_file}" || die
    insinto /usr/share/applications
    newins "${desktop_file}" "zen-browser.desktop"
  fi

  if [[ -d squashfs-root/usr/share/icons ]]; then
    insinto /usr/share/icons
    doins -r squashfs-root/usr/share/icons/*
  fi

  dosym "/opt/${PN}/zen-browser.AppImage" /usr/bin/zen-browser
  dosym "/opt/${PN}/zen-browser.AppImage" /usr/bin/zen
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
