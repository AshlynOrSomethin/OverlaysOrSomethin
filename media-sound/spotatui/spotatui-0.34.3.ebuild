EAPI=8

inherit desktop

DESCRIPTION="spotatui - a terminal Spotify client (prebuilt binary)"
HOMEPAGE="https://github.com/LargeModGames/spotatui"
SRC_URI="https://github.com/LargeModGames/spotatui/releases/download/v${PV}/spotatui-linux-x86_64.tar.gz -> ${P}-linux-x86_64.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"

# Prebuilt static-ish binary; don't strip/debug
RESTRICT="mirror strip"

S="${WORKDIR}"

src_compile() { :; }

src_install() {
  # Archive contains a single binary 'spotatui'
  dobin spotatui || die "spotatui binary not found in archive"

  # Minimal desktop integration (optional but handy)
  # Provide a simple icon if you add one to FILESDIR later.
  make_desktop_entry spotatui "spotatui" "" "AudioVideo;Player;ConsoleOnly;"
  dodoc README.md 2>/dev/null || true
}
