# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="A simple editor for simple needs (Microsoft Edit)"
HOMEPAGE="https://github.com/microsoft/edit"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Build from upstream Git tag v1.2.1
EGIT_REPO_URI="https://github.com/microsoft/edit.git"
EGIT_TAG="v${PV}"

# Allow network during build (for Cargo crates) and fetch directly (no Gentoo mirrors)
RESTRICT="network-sandbox mirror"

RDEPEND="
  x11-themes/hicolor-icon-theme
  dev-libs/icu:=
"
BDEPEND="
  dev-lang/rust
  net-misc/curl
  dev-vcs/git
"

# git-r3 checks out into ${WORKDIR}/${P}
S="${WORKDIR}/${P}"

src_prepare() {
  default
  # Make the .desktop Exec refer to msedit (the installed binary name)
  sed -i 's/^\(Exec=\)edit/\1msedit/' assets/com.microsoft.edit.desktop || die
}

src_compile() {
  export CC=${CC:-clang}
  # Use a clean cargo cache in the tempdir to avoid host pollution
  export CARGO_HOME="${T}/cargo-home"

  # Fetch crates and build in release mode (network enabled)
  cargo fetch --locked || die
  cargo build --locked --release || die
}

src_test() {
  # Optional: run tests if you want
  # cargo test --frozen || die
  :
}

src_install() {
  # Install binary as msedit
  dobin target/release/edit
  mv "${ED}/usr/bin/edit" "${ED}/usr/bin/msedit" || die

  # Icon
  insinto /usr/share/icons/hicolor/scalable/apps
  newins assets/edit.svg msedit.svg

  # Desktop entry
  domenu assets/com.microsoft.edit.desktop

  # License
  insinto /usr/share/licenses/${PN}
  doins LICENSE
}
