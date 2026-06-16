EAPI=8

inherit xdg-utils

DESCRIPTION="XPipe infrastructure shell connection hub (binary)"
HOMEPAGE="https://xpipe.io/ https://github.com/xpipe-io/xpipe"
SRC_URI="amd64? ( https://github.com/xpipe-io/xpipe/releases/download/${PV}/xpipe-installer-linux-x86_64.deb -> ${P}-x86_64.deb )"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

RDEPEND="
  media-video/ffmpeg
  x11-libs/gtk+:3
  x11-libs/libX11
  media-libs/alsa-lib
"

S="${WORKDIR}"
QA_PREBUILT="*"

src_unpack() {
  ar x "${DISTDIR}/${P}-x86_64.deb" || die

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
  if [[ -d opt/xpipe ]]; then
    insinto /usr/lib
    doins -r opt/xpipe
  else
    die "Expected opt/xpipe in package payload"
  fi

  # The payload is installed with doins, so restore executable bits for launchers.
  if [[ -d ${D}/usr/lib/xpipe/bin ]]; then
    find "${D}/usr/lib/xpipe/bin" -type f -exec chmod 0755 {} + || die
  fi
  if [[ -d ${D}/usr/lib/xpipe/lib/runtime/bin ]]; then
    find "${D}/usr/lib/xpipe/lib/runtime/bin" -type f -exec chmod 0755 {} + || die
  fi

  cat > "${T}/xpipe" <<'EOF' || die
#!/bin/sh
_APPDIR="/usr/lib/xpipe"
_RUNNAME="${_APPDIR}/bin/xpipe"

# Some Wayland sessions don't export DISPLAY into user shells.
# XPipe's Java UI still requires X11 display discovery via DISPLAY.
if [ -z "${DISPLAY}" ] && [ -n "${WAYLAND_DISPLAY}" ]; then
  for xsock in /tmp/.X11-unix/X*; do
    [ -S "${xsock}" ] || continue
    xnum=${xsock##*/X}
    case "${xnum}" in
      ''|*[!0-9]*) continue ;;
    esac
    export DISPLAY=":${xnum}"
    break
  done

  if [ -z "${DISPLAY}" ] && command -v pgrep >/dev/null 2>&1; then
    xwpid=$(pgrep -u "$(id -u)" -n Xwayland 2>/dev/null || true)
    if [ -n "${xwpid}" ] && [ -r "/proc/${xwpid}/cmdline" ]; then
      xwargs=$(tr '\0' ' ' < "/proc/${xwpid}/cmdline")
      set -- ${xwargs}
      for arg in "$@"; do
        case "${arg}" in
          :[0-9]*)
            export DISPLAY="${arg}"
            break
            ;;
        esac
      done
    fi
  fi
fi

export PATH="${_APPDIR}/bin:${_APPDIR}/lib/runtime/bin:${PATH}"
export LD_LIBRARY_PATH="${_APPDIR}/lib/runtime/lib:${LD_LIBRARY_PATH}"
cd "${_APPDIR}" || exit 1
exec "${_RUNNAME}" "$@"
EOF
  dobin "${T}/xpipe"

  if [[ -f opt/xpipe/xpipe.desktop ]]; then
    sed -e 's|^TryExec=.*|TryExec=/usr/lib/xpipe/bin/xpiped|' \
        -e 's|^Exec=.*|Exec=xpipe|' \
        -e 's|^Path=.*|Path=/usr/lib/xpipe|' \
        opt/xpipe/xpipe.desktop > "${T}/xpipe.desktop" || die
    insinto /usr/share/applications
    newins "${T}/xpipe.desktop" xpipe.desktop
  fi

  if [[ -d usr/share/icons ]]; then
    insinto /usr/share/icons
    doins -r usr/share/icons/*
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
