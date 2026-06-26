# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg

WINE_SUFFIX="cachyos-10.0.20260425"
WINE_SLOT="wine-${WINE_SUFFIX}"

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
	tar --zstd -xpf "${DISTDIR}/${P}.pkg.tar.zst" -C "${D}" \
		--exclude='.BUILDINFO' \
		--exclude='.INSTALL' \
		--exclude='.MTREE' \
		--exclude='.PKGINFO' || die

	# Map upstream layout into eselect-wine slot layout.
	mkdir -p "${D}/usr/lib/${WINE_SLOT}" || die
	if [[ -d "${D}/usr/lib/wine" ]]; then
		mv "${D}/usr/lib/wine" "${D}/usr/lib/${WINE_SLOT}/wine" || die
	fi
	if [[ -d "${D}/usr/include/wine" ]]; then
		mv "${D}/usr/include/wine" "${D}/usr/include/${WINE_SLOT}" || die
	fi
	if [[ -d "${D}/usr/share/wine" ]]; then
		mv "${D}/usr/share/wine" "${D}/usr/share/${WINE_SLOT}" || die
	fi

	mkdir -p "${D}/usr/lib/${WINE_SLOT}/bin" || die
	local bin name
	for bin in "${D}/usr/bin"/*; do
		[[ -f ${bin} ]] || continue
		name=${bin##*/}
		ln -snf "../../../bin/${name}" "${D}/usr/lib/${WINE_SLOT}/bin/${name}" || die
		ln -snf "${name}" "${D}/usr/bin/${name}-${WINE_SUFFIX}" || die
	done

	# Upstream package ships these as .gz symlinks but only .bz2 manpages exist.
	rm -f "${D}/usr/share/man/man1/winecpp.1.gz" || die
	rm -f "${D}/usr/share/man/man1/wineg++.1.gz" || die

	dosym wine /usr/bin/wine-cachyos
}

pkg_postinst() {
	einfo "Installed CachyOS binary package: wine-cachyos 2:10.0.20260425-1"
	einfo "Launch with: wine-cachyos (or wine)"

	eselect wine update --if-unset >/dev/null 2>&1 || \
		ewarn "eselect wine update failed; run 'eselect wine list' and 'eselect wine set ...' manually"

	xdg_desktop_database_update
}

pkg_postrm() {
	has_version -b app-eselect/eselect-wine && eselect wine update --if-unset >/dev/null 2>&1 || true

	xdg_desktop_database_update
}
