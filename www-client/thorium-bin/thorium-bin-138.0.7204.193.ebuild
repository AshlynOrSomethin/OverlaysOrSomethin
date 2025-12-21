EAPI=8
inherit desktop xdg-utils

DESCRIPTION="Thorium Browser (binary, installed from upstream .deb)"
HOMEPAGE="https://thorium.rocks"
SRC_URI="
  amd64? ( https://github.com/Alex313031/thorium/releases/download/M138Beta1/thorium-browser_138.0.7204.193_BETA_1.deb -> thorium_amd64_138.0.7204.193_BETA_1.deb )
  https://thorium.rocks/imgs/thorium.svg -> thorium-browser.svg
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

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
  local tarball=
  for tarball in data.tar.zst data.tar.xz data.tar.gz; do
    if [[ -f ${tarball} ]]; then
      tar xf "${tarball}" || die
      break
    fi
  done
}

src_install() {
  # Prune thorium-shell/content_shell payloads before installing
  rm -f usr/bin/thorium-shell || true
  rm -f usr/share/applications/thorium-shell.desktop || true

  if [[ -d opt/chromium.org/thorium ]]; then
    rm -f opt/chromium.org/thorium/thorium_shell || true
    rm -f opt/chromium.org/thorium/thorium_shell.png || true
    rm -f opt/chromium.org/thorium/content_shell.pak || true
    rm -f opt/chromium.org/thorium/shell_resources.pak || true
    find opt/chromium.org/thorium -maxdepth 1 -type f \
      \( -name 'thorium_shell*' -o -name 'content_shell*' -o -name 'shell_*' \) \
      -delete || true
  fi

  # Install payload
  if [[ -d usr ]]; then
    cp -a usr "${D}"/ || die
  fi
  if [[ -d opt ]]; then
    cp -a opt "${D}"/ || die
  fi

  # Ensure a 'thorium' convenience symlink
  if [[ -x ${D}/usr/bin/thorium-browser && ! -e ${D}/usr/bin/thorium ]]; then
    ln -s thorium-browser "${D}/usr/bin/thorium" || die
  fi

  # Fix or replace desktop entry to reference /usr/bin and the icon name
  install -d "${D}/usr/share/applications" || die
  if [[ -f ${D}/usr/share/applications/thorium-browser.desktop ]]; then
    sed -i \
      -e 's|^Exec=.*|Exec=/usr/bin/thorium-browser %U|' \
      -e 's|^Icon=.*|Icon=thorium-browser|' \
      "${D}/usr/share/applications/thorium-browser.desktop" || die
  else
    cat > "${D}/usr/share/applications/thorium-browser.desktop" <<'EOF' || die
[Desktop Entry]
Name=Thorium Browser
GenericName=Web Browser
Comment=Browse the web
Exec=/usr/bin/thorium-browser %U
Terminal=false
Type=Application
Icon=thorium-browser
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;
StartupWMClass=thorium-browser
StartupNotify=true
EOF
  fi
  # Remove extra/duplicate desktop entry if present
  rm -f "${D}/usr/share/applications/org.chromium.Thorium.desktop" || true

  # Install upstream SVG icon to hicolor
  install -d "${D}/usr/share/icons/hicolor/scalable/apps" || die
  install -m644 "${DISTDIR}/thorium-browser.svg" \
    "${D}/usr/share/icons/hicolor/scalable/apps/thorium-browser.svg" || die

  # Also install PNG sizes for themes that prefer raster icons
  install_icon() {
    local size="$1"
    local src="${D}/opt/chromium.org/thorium/product_logo_${size}.png"
    local dest="${D}/usr/share/icons/hicolor/${size}x${size}/apps"
    [[ -f ${src} ]] || return 0
    mkdir -p "${dest}" || die
    cp "${src}" "${dest}/thorium-browser.png" || die
  }
  for s in 16 24 32 48 64 128 256; do install_icon "$s"; done

  # Permissions for binaries
  if [[ -d ${D}/usr/bin ]]; then
    find "${D}/usr/bin" -type f -executable -exec chmod 0755 {} + || die
  fi
}

pkg_postinst() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  type xdg_icon_cache_update >/dev/null 2>&1 && xdg_icon_cache_update
  type update_icon_caches >/dev/null 2>&1 && update_icon_caches
  elog "Thorium binary installed from upstream .deb."
}

pkg_postrm() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
  type xdg_icon_cache_update >/dev/null 2>&1 && xdg_icon_cache_update
  type update_icon_caches >/dev/null 2>&1 && update_icon_caches
}
