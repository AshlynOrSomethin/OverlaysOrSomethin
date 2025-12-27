EAPI=8

DESCRIPTION="Lightweight, fast terminal text editor with LSP support and TypeScript plugins"
HOMEPAGE="https://sinelaw.github.io/fresh/"
SRC_URI="https://github.com/sinelaw/fresh/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

# Do not try Gentoo mirrors for the upstream tarball; fetch directly.
RESTRICT="mirror network-sandbox"

BDEPEND="
  virtual/rust
  llvm-core/clang
  net-misc/curl
  dev-vcs/git
"
RDEPEND=""

S="${WORKDIR}/fresh-${PV}"

src_compile() {
  export CC=${CC:-clang}
  export CARGO_HOME="${T}/cargo-home"
  cargo fetch --locked
  cargo build --frozen --release
}

src_install() {
  dobin target/release/fresh
  insinto /usr/share/${PN}
  doins -r plugins keymaps
  dodoc README.md
  insinto /usr/share/licenses/${PF}
  doins LICENSE
}
