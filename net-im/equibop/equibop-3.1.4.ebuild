EAPI=8

inherit desktop

DESCRIPTION="Equibop (prebuilt Linux x86_64 bundle)."
HOMEPAGE="https://github.com/Equicord/Equibop"
# MUST be the Releases asset, not the source archive
SRC_URI="https://github.com/Equicord/Equibop/releases/download/v${PV}/equibop-${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip"

S=${WORKDIR}

_find_bundle_dir() {
  # Prefer prebuilt bundle: linux-unpacked
  if [[ -d ${S}/linux-unpacked ]]; then
    echo linux-unpacked; return 0
  fi
  # If user accidentally fetched source archive, bail out with a helpful msg
  if [[ -d ${S}/Equibop-${PV} ]]; then
    eerror "You downloaded the source archive, not the prebuilt bundle."
    eerror "Expected: releases/download/v${PV}/equibop-${PV}.tar.gz"
    eerror "Got: archive/refs/tags/v${PV}.tar.gz (source)"
    return 1
  fi
  # Fallback search for a dir containing the binary
  local d
  d=$(find "${S}" -mindepth 1 -maxdepth 2 -type f \( -name equibop -o -name Equibop \) -printf '%h\n' | head -n1)
  if [[ -n ${d} ]]; then
    d=${d#${S}/}
    echo "${d}"
    return 0
  fi
  return 1
}

src_compile() { :; }

src_install() {
  local dir bin
  dir=$(_find_bundle_dir) || die "Prebuilt bundle not found in tarball; ensure SRC_URI points to releases/download/v${PV}/equibop-${PV}.tar.gz"

  insinto /opt/equibop
  doins -r "${dir}" || die

  if [[ -x ${S}/${dir}/equibop ]]; then
    bin="equibop"
  elif [[ -x ${S}/${dir}/Equibop ]]; then
    bin="Equibop"
  else
    die "Equibop binary not found in ${dir}"
  fi

  fperms +x "/opt/equibop/${dir}/${bin}"

  if [[ -f ${S}/${dir}/resources/app/static/icon.png ]]; then
    newicon "${S}/${dir}/resources/app/static/icon.png" equibop.png
  fi

  dosym "/opt/equibop/${dir}/${bin}" /usr/bin/equibop
  make_desktop_entry /usr/bin/equibop "Equibop" equibop "Network;Chat;InstantMessaging;"
}
