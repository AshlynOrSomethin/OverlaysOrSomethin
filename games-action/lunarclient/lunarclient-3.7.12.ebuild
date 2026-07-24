EAPI=8
inherit xdg-utils

DESCRIPTION="PvP Modpack for Minecraft (Lunar Client AppImage, binary)"
HOMEPAGE="https://lunarclient.com"
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="mirror strip"

_pkgname="lunarclient"
_appimage_remote="Lunar%20Client-${PV}-ow.AppImage"
_appimage_local="${PN}-${PV}.AppImage"

SRC_URI="
  amd64? ( https://launcherupdates.lunarclientcdn.com/${_appimage_remote} -> ${_appimage_local} )
"

S="${WORKDIR}"
QA_PREBUILT="*"

# AppImage bundles most shared libs; keep minimal host runtime requirements.
RDEPEND="
  sys-fs/fuse:0
  x11-apps/xrandr
"

src_unpack() {
  :
}

src_prepare() {
  default

  cp "${DISTDIR}/${_appimage_local}" "${S}/${_appimage_local}" || die
  chmod +x "${_appimage_local}" || die
  "./${_appimage_local}" --appimage-extract || die
}

src_compile() {
  if [[ -f "squashfs-root/${_pkgname}.desktop" ]]; then
    # Match AUR behavior: run unpacked desktop file outside AppImage container.
    sed -i -E \
      "s|Exec=AppRun|Exec=env DESKTOPINTEGRATION=false /usr/bin/${_pkgname}|" \
      "squashfs-root/${_pkgname}.desktop" || die
  else
    die "${_pkgname}.desktop not found in AppImage (squashfs-root)"
  fi

  if [[ -d squashfs-root/usr ]]; then
    chmod -R a-x+rX squashfs-root/usr || die
  fi
}

src_install() {
  # AppImage
  exeinto "/opt/${_pkgname}"
  newexe "${_appimage_local}" "${_pkgname}.AppImage"

  # Desktop file
  insinto /usr/share/applications
  newins "squashfs-root/${_pkgname}.desktop" "${_pkgname}.desktop"

  # Icon images
  if [[ -d squashfs-root/usr/share/icons ]]; then
    insinto /usr/share/icons
    doins -r squashfs-root/usr/share/icons/*
  fi

  # Symlink executable
  dosym "/opt/${_pkgname}/${_pkgname}.AppImage" "/usr/bin/${_pkgname}"
  dosym "/opt/${_pkgname}/${_pkgname}.AppImage" "/usr/bin/${PN}"
}

pkg_postinst() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  type xdg_icon_cache_update   >/dev/null 2>&1 && xdg_icon_cache_update
  type update_icon_caches      >/dev/null 2>&1 && update_icon_caches
  elog "Lunar Client installed. Launch with: lunarclient"
}

pkg_postrm() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  type xdg_icon_cache_update   >/dev/null 2>&1 && xdg_icon_cache_update
  type update_icon_caches      >/dev/null 2>&1 && update_icon_caches
}