EAPI=8

DESCRIPTION="Thorium Browser (binary, installed from upstream .deb)"
HOMEPAGE="https://thorium.rocks"
SRC_URI="
  amd64? ( https://github.com/Alex313031/thorium/releases/download/M138Beta1/thorium-browser_138.0.7204.193_BETA_1.deb -> thorium_amd64_138.0.7204.193_BETA_1.deb )
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip mirror"

# This is a best-effort dependency set commonly needed by Chromium-based binaries.
# You can refine after first install by running ldd on the main binary.
RDEPEND="
  dev-libs/expat
  dev-libs/nspr
  dev-libs/nss
  dev-libs/icu
  media-libs/alsa-lib
  media-libs/fontconfig
  media-libs/freetype
  media-libs/harfbuzz:0[icu]
  media-libs/libwebp
  media-libs/mesa
  media-libs/woff2
  sys-apps/dbus
  sys-libs/zlib[minizip]
  x11-libs/cairo
  x11-libs/gdk-pixbuf:2
  x11-libs/gtk+:3
  x11-libs/libX11
  x11-libs/libXcomposite
  x11-libs/libXcursor
  x11-libs/libXdamage
  x11-libs/libXext
  x11-libs/libXfixes
  x11-libs/libXi
  x11-libs/libXrandr
  x11-libs/libXrender
  x11-libs/libXtst
  x11-libs/libxcb
  x11-libs/libxkbcommon
  x11-libs/pango
"

S="${WORKDIR}"
QA_PREBUILT="*"

src_unpack() {
  ar x "${DISTDIR}/thorium_amd64_138.0.7204.193_BETA_1.deb" || die
  # Control/data tar can be xz or zstd depending on deb build
  local tarball=
  for tarball in data.tar.zst data.tar.xz data.tar.gz; do
    if [[ -f ${tarball} ]]; then
      tar xf "${tarball}" || die
      break
    fi
  done
}

src_install() {
  # Install everything from the .deb payload
  if [[ -d usr ]]; then
    cp -a usr "${D}"/ || die
  fi
  if [[ -d opt ]]; then
    cp -a opt "${D}"/ || die
  fi

  # Ensure a thorium symlink for convenience if only thorium-browser is present
  if [[ -x ${D}/usr/bin/thorium-browser && ! -e ${D}/usr/bin/thorium ]]; then
    ln -s thorium-browser "${D}/usr/bin/thorium" || die
  fi

  # Basic perms for bins
  if [[ -d ${D}/usr/bin ]]; then
    find "${D}/usr/bin" -type f -executable -exec chmod 0755 {} + || die
  fi

  # Post-install caches handled in pkg_postinst/pkg_postrm
}

pkg_postinst() {
  xdg_icon_cache_update
  xdg_desktop_database_update

  elog "Thorium binary installed from upstream .deb."
  elog "If video decode via VA-API is desired, you may add flags like:"
  elog "  --enable-features=VaapiVideoDecoder"
  elog "And ensure proper VA-API drivers (media-libs/libva, mesa VA drivers, etc.)."
}

pkg_postrm() {
  xdg_icon_cache_update
  xdg_desktop_database_update
}
