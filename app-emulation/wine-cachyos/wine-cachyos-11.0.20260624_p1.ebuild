# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools wrapper

COMMIT="8d29c562d31e84b2817305c0f576832207e39578"
SRC_URI="https://github.com/CachyOS/wine-cachyos/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

DESCRIPTION="CachyOS Wine (staging branch snapshot source build)"
HOMEPAGE="https://github.com/CachyOS/wine-cachyos"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

RDEPEND="
	dev-libs/glib:2
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype:2
	media-libs/libglvnd
	media-libs/libpulse
	net-libs/gnutls
	sys-libs/zlib
	x11-libs/libX11
	x11-libs/libXext
"

DEPEND="
	${RDEPEND}
	sys-devel/bison
	sys-devel/flex
	sys-devel/gettext
	virtual/pkgconfig
"

S="${WORKDIR}/${PN}-${COMMIT}"

src_prepare() {
	default

	# GitHub source archives do not include generated configure scripts.
	eautoreconf
}

src_configure() {
	mkdir -p build || die
	pushd build >/dev/null || die
	econf \
		--prefix="/opt/${PF}" \
		--disable-tests \
		--enable-win64
	popd >/dev/null || die
}

src_compile() {
	emake -C build
}

src_install() {
	emake -C build DESTDIR="${D}" install

	if [[ -x "${ED}/opt/${PF}/bin/wine" ]]; then
		make_wrapper wine-cachyos "/opt/${PF}/bin/wine"
	fi
	if [[ -x "${ED}/opt/${PF}/bin/wine64" ]]; then
		make_wrapper wine64-cachyos "/opt/${PF}/bin/wine64"
	fi

	dodoc README.md ANNOUNCE.md
}

pkg_postinst() {
	einfo "Installed snapshot commit: ${COMMIT:0:12} from cachyos_11.0_release/_staging"
	einfo "Launch with: wine-cachyos"
}