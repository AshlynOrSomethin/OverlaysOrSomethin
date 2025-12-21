EAPI=8
inherit desktop

DESCRIPTION="spotatui - a terminal Spotify client (prebuilt binary)"
HOMEPAGE="https://github.com/LargeModGames/spotatui"
SRC_URI="https://github.com/LargeModGames/spotatui/releases/download/v${PV}/spotatui-linux-x86_64.tar.gz -> ${P}-linux-x86_64.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="mirror strip"

S=${WORKDIR}

src_compile() { :; }

src_install() {
  dobin spotatui || die "spotatui binary not found"
  make_desktop_entry spotatui "spotatui" "" "AudioVideo;Player;ConsoleOnly;"
  [[ -f README.md ]] && dodoc README.md
}
