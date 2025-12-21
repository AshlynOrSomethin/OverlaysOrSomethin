EAPI=8
inherit desktop xdg-utils
DESCRIPTION="Thorium Browser (binary, installed from upstream .deb)"
HOMEPAGE="https://thorium.rocks"
SRC_URI="
  amd64? ( https://github.com/Alex313031/thorium/releases/download/M138Beta1/thorium-browser_138.0.7204.193_BETA_1.deb -> thorium_amd64_138.0.7204.193_BETA_1.deb )
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
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
  # Prune thorium-shell and content_shell payloads from the unpacked deb tree
  # Do it before copying to ${D} so Portage never sees them.

  # Binaries/wrappers
  rm -f usr/bin/thorium-shell || true

  # Desktop entries and appdata
  rm -f usr/share/applications/thorium-shell.desktop || true

  # Icons/images and shell resources under /opt
  if [[ -d opt/chromium.org/thorium ]]; then
    rm -f opt/chromium.org/thorium/thorium_shell || true
    rm -f opt/chromium.org/thorium/thorium_shell.png || true
    rm -f opt/chromium.org/thorium/content_shell.pak || true
    rm -f opt/chromium.org/thorium/shell_resources.pak || true
    # Any other shell-named files just in case
    find opt/chromium.org/thorium -maxdepth 1 -type f \
      \( -name 'thorium_shell*' -o -name 'content_shell*' -o -name 'shell_*' \) \
      -delete || true
  fi

  # Now install everything from the .deb payload
  if [[ -d usr ]]; then
    cp -a usr "${D}"/ || die
  fi
  if [[ -d opt ]]; then
    cp -a opt "${D}"/ || die
  fi

  # Ensure a 'thorium' convenience symlink for the browser
  if [[ -x ${D}/usr/bin/thorium-browser && ! -e ${D}/usr/bin/thorium ]]; then
    ln -s thorium-browser "${D}/usr/bin/thorium" || die
  fi

  # Permissions for binaries
  if [[ -d ${D}/usr/bin ]]; then
    find "${D}/usr/bin" -type f -executable -exec chmod 0755 {} + || die
  fi
}

pkg_postinst() {
  # desktop eclass
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  # xdg-utils eclass (new)
  type xdg_icon_cache_update >/dev/null 2>&1 && xdg_icon_cache_update
  # xdg-utils eclass (older)
  type update_icon_caches >/dev/null 2>&1 && update_icon_caches

  elog "Thorium binary installed from upstream .deb."
}

pkg_postrm() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  type xdg_icon_cache_update >/dev/null 2>&1 && xdg_icon_cache_update
  type update_icon_caches >/dev/null 2>&1 && update_icon_caches
}
