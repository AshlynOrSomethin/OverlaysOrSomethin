# Copyright 2025
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="A simple editor for simple needs (Microsoft Edit)"
HOMEPAGE="https://github.com/microsoft/edit"
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"

# Build from the v1.2.1 tag
EGIT_REPO_URI="https://github.com/microsoft/edit.git"
EGIT_TAG="v${PV}"

# Runtime deps: glibc/gcc-libs are part of @system on Gentoo; hicolor for icon cache
RDEPEND="
  x11-themes/hicolor-icon-theme
  dev-libs/icu:=
"
# Build deps: rust toolchain
BDEPEND="
  dev-lang/rust
"

# git-r3 will clone into ${WORKDIR}/${P}/. The crate root has Cargo.toml at top.
S="${WORKDIR}/${P}"

src_prepare() {
  default
  # Match Arch: alter the desktop file to use msedit as binary name
  sed -i 's/\(Exec=\)edit/\1msedit/' assets/com.microsoft.edit.desktop || die
}

src_compile() {
  # Build release binary
  cargo build --locked --frozen --release || die
}

src_test() {
  cargo test --frozen || die
}

src_install() {
  # Install binary under the Gentoo name msedit
  dobin target/release/edit
  # Rename installed binary to msedit (keep upstream name in build dir)
  mv "${ED}"/usr/bin/edit "${ED}"/usr/bin/msedit || die

  # Icon (SVG, scalable)
  insinto /usr/share/icons/hicolor/scalable/apps
  newins assets/edit.svg msedit.svg

  # Desktop entry
  domenu assets/com.microsoft.edit.desktop

  # License
  insinto /usr/share/licenses/${PN}
  doins LICENSE
}
