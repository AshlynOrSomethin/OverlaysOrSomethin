# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg

DESCRIPTION="CachyOS Wine prebuilt binary package"
HOMEPAGE="https://github.com/CachyOS/wine-cachyos"
SRC_URI="https://cdn77.cachyos.org/repo/x86_64/cachyos/wine-cachyos-2%3A10.0.20260425-1-x86_64.pkg.tar.zst -> ${P}.pkg.tar.zst"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"

RDEPEND="
	app-eselect/eselect-wine
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
	local slot_dir="wine-cachyos-10.0.20260425"

	tar --zstd -xpf "${DISTDIR}/${P}.pkg.tar.zst" -C "${D}" \
		--exclude='.BUILDINFO' \
		--exclude='.INSTALL' \
		--exclude='.MTREE' \
		--exclude='.PKGINFO' || die

	# eselect-wine manages /usr/include/wine, avoid replacing it with a real dir.
	rm -rf "${D}/usr/include/wine" || die

	# Register a slot layout that eselect-wine can discover and activate.
	dodir "/usr/lib/${slot_dir}/bin"
	local bin
	for bin in "${ED}"/usr/bin/*; do
		[[ -f ${bin} ]] || continue
		dosym "../../../bin/${bin##*/}" "/usr/lib/${slot_dir}/bin/${bin##*/}"
	done
	dosym "../wine" "/usr/lib/${slot_dir}/wine"
	dodir "/usr/include/${slot_dir}"
	dosym "wine" "/usr/share/${slot_dir}"

	# Upstream package ships these as .gz symlinks but only .bz2 manpages exist.
	rm -f "${D}/usr/share/man/man1/winecpp.1.gz" || die
	rm -f "${D}/usr/share/man/man1/wineg++.1.gz" || die

	dosym wine /usr/bin/wine-cachyos
}

pkg_postinst() {
	einfo "Installed CachyOS binary package: wine-cachyos 2:10.0.20260425-1"
	einfo "Launch with: wine-cachyos (or wine)"

	if has_version -b app-eselect/eselect-wine; then
		eselect wine update --if-unset >/dev/null 2>&1 || \
			ewarn "eselect wine update failed; run 'eselect wine list' and 'eselect wine set ...' manually"
	fi

	xdg_desktop_database_update
}

pkg_postrm() {
	if has_version -b app-eselect/eselect-wine; then
		eselect wine update --if-unset >/dev/null 2>&1 || true
	fi

	xdg_desktop_database_update
}
