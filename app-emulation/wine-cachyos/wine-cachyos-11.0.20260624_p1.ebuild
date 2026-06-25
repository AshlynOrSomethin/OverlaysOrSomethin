# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="CachyOS Wine prebuilt binary package"
HOMEPAGE="https://github.com/CachyOS/wine-cachyos"
SRC_URI="https://cdn77.cachyos.org/repo/x86_64/cachyos/wine-cachyos-2%3A10.0.20260425-1-x86_64.pkg.tar.zst -> ${P}.pkg.tar.zst"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

RDEPEND="
	!app-emulation/wine
	dev-libs/glib:2
	dev-libs/wayland
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype:2
	media-libs/libpulse
	net-libs/libpcap
	sys-apps/attr
	sys-apps/systemd
	sys-devel/gettext
	sys-libs/libunwind
	sys-libs/zlib
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libxkbcommon
"

DEPEND="${RDEPEND}"
BDEPEND="app-arch/zstd"

S="${WORKDIR}"

src_install() {
	tar --zstd -xpf "${DISTDIR}/${P}.pkg.tar.zst" -C "${D}" \
		--exclude='.BUILDINFO' \
		--exclude='.INSTALL' \
		--exclude='.MTREE' \
		--exclude='.PKGINFO' || die
	dosym wine /usr/bin/wine-cachyos
}

pkg_postinst() {
	einfo "Installed CachyOS binary package: wine-cachyos 2:10.0.20260425-1"
	einfo "Launch with: wine-cachyos (or wine)"
}
