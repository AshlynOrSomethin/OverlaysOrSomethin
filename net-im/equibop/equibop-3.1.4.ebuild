# Copyright 2025
# Distributed under the terms of the GNU General Public License v3

EAPI=8

inherit desktop

DESCRIPTION="Equibop is a fork of Vesktop."
HOMEPAGE="https://github.com/Equicord/Equibop"
SRC_URI="https://github.com/Equicord/Equibop/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
# Use amd64 for stable in your overlay; change to ~amd64 if you prefer testing
KEYWORDS="amd64"

# Building needs network for npm/bun fetches unless upstream vendors deps
# If your build works fully offline after 'bun install', you can drop this.
RESTRICT="network-sandbox"

# Build-time deps. Node is not needed if build uses bun only.
BDEPEND="
  net-libs/bun-bin
"

# Add runtime deps if needed by the app; most Electron-style bundles are self-contained
RDEPEND=""

S="${WORKDIR}/Equibop-${PV}"

# If upstream requires environment vars, set them here
# For reproducibility, avoid writing to $HOME
PATCHES=()

src_prepare() {
  default
  # Install JS deps with Bun. --no-progress to quiet logs inside Portage.
  # If upstream provides a lockfile, keep --frozen-lockfile.
  bun install --frozen-lockfile --no-progress || die "bun install failed"
}

src_compile() {
  # Upstream build script
  bun run scripts/build/build.mts || die "build script failed"

  # Verify expected output exists; adjust the path if upstream changes it.
  if [[ ! -x dist/linux-unpacked/equibop && ! -f dist/linux-unpacked/equibop ]]; then
    die "expected build output 'dist/linux-unpacked/equibop' not found"
  fi
}

src_install() {
  # Install application under /opt/equibop
  insinto /opt/equibop
  doins -r dist/linux-unpacked || die "installing linux-unpacked failed"

  # Ensure binary is executable
  fperms +x /opt/equibop/linux-unpacked/equibop

  # Icons/desktop entry
  newicon static/icon.png equibop.png
  make_desktop_entry /opt/equibop/linux-unpacked/equibop "Equibop" equibop \
    "Network;Chat;InstantMessaging;"

  # Convenience symlink
  dosym /opt/equibop/linux-unpacked/equibop /usr/bin/equibop
}
