EAPI=8
inherit desktop xdg-utils

DESCRIPTION="PvP modpack for modern Minecraft (Lunar Client AppImage, binary)"
HOMEPAGE="https://lunarclient.com"
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

# Upstream filename pattern includes '-ow' for this version
APPIMAGE_REMOTE="Lunar%20Client-${PV}-ow.AppImage"
# Rename locally for a stable distfile name
APPIMAGE_LOCAL="${PN}-${PV}.AppImage"

SRC_URI="
  amd64? ( https://launcherupdates.lunarclientcdn.com/${APPIMAGE_REMOTE} -> ${APPIMAGE_LOCAL} )
"

S="${WORKDIR}"
QA_PREBUILT="*"

# Runtime deps similar to Arch's depends
RDEPEND="
  sys-fs/fuse:0
  x11-apps/xrandr
"

src_unpack() {
  :
}

src_prepare() {
  default

  # Stage and extract AppImage
  cp "${DISTDIR}/${APPIMAGE_LOCAL}" "${S}/${APPIMAGE_LOCAL}" || die
  chmod +x "${APPIMAGE_LOCAL}" || die
  "./${APPIMAGE_LOCAL}" --appimage-extract || die

  # Ensure desktop entry launches system wrapper (not AppRun)
  if [[ -f squashfs-root/lunarclient.desktop ]]; then
    # We'll make the user-facing command 'lunarclient'
    sed -i -E \
      "s|^Exec=.*|Exec=env DESKTOPINTEGRATION=false /usr/bin/lunarclient|" \
      squashfs-root/lunarclient.desktop || die
  else
    die "lunarclient.desktop not found in AppImage (squashfs-root)"
  fi

  # AppImage often ships 700 perms; relax for icons/resources
  if [[ -d squashfs-root/usr ]]; then
    chmod -R a-x+rX squashfs-root/usr || die
  fi
}

src_install() {
  # Install AppImage under /opt/${PN}
  exeinto "/opt/${PN}"
  newexe "${APPIMAGE_LOCAL}" "${PN}.AppImage"

  # Desktop entry
  insinto /usr/share/applications
  newins squashfs-root/lunarclient.desktop "lunarclient.desktop"

  # Icons from AppImage (hicolor theme)
  if [[ -d squashfs-root/usr/share/icons ]]; then
    insinto /usr/share/icons
    doins -r squashfs-root/usr/share/icons/*
  fi

  # Provide convenient launchers:
  # - user-facing 'lunarclient'
  # - package-named 'lunar-client-bin'
  dosym "/opt/${PN}/${PN}.AppImage" "/usr/bin/lunarclient"
  dosym "/opt/${PN}/${PN}.AppImage" "/usr/bin/${PN}"
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
