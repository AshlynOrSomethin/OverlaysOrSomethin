# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit wrapper

MY_DATE="${PV##*.}"
MY_BASE="${PV%.*}"
MY_TAG="cachyos-${MY_BASE}-${MY_DATE}-slr"

DESCRIPTION="CachyOS Proton build with NTSync support and performance optimizations"
HOMEPAGE="https://github.com/CachyOS/proton-cachyos"

SRC_URI="
	cpu_flags_x86_avx2? (
		https://github.com/CachyOS/proton-cachyos/releases/download/${MY_TAG}/proton-cachyos-${MY_BASE}-${MY_DATE}-slr-x86_64_v3.tar.xz
	)
	!cpu_flags_x86_avx2? (
		https://github.com/CachyOS/proton-cachyos/releases/download/${MY_TAG}/proton-cachyos-${MY_BASE}-${MY_DATE}-slr-x86_64.tar.xz
	)
"

LICENSE="BSD BSD-2 LGPL-2.1+ ZLIB gsm libpng2 libtiff MIT OPENLDAP"
SLOT="${PV}"
KEYWORDS="-* ~amd64"
IUSE="+abi_x86_32 +abi_x86_64 +cpu_flags_x86_avx2"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )"

RDEPEND="
	app-emulation/wine-desktop-common
	dev-libs/glib:2
	dev-libs/libgcrypt:0
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype:2
	media-libs/libglvnd
	media-libs/libpulse
	media-libs/libsdl2
	media-libs/vulkan-loader
	media-video/ffmpeg
	net-libs/gnutls
	sys-apps/dbus
	sys-libs/zlib
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXxf86vm
	abi_x86_32? (
		dev-libs/glib:2[abi_x86_32]
		media-libs/alsa-lib[abi_x86_32]
		media-libs/fontconfig[abi_x86_32]
		media-libs/freetype:2[abi_x86_32]
		media-libs/libglvnd[abi_x86_32]
		media-libs/vulkan-loader[abi_x86_32]
		x11-libs/libX11[abi_x86_32]
		x11-libs/libXext[abi_x86_32]
	)
"
IDEPEND=">=app-eselect/eselect-wine-2"

RESTRICT="mirror strip"

WINE_PREFIX="/usr/lib/${PN}-${PV}"
WINE_DATADIR="/usr/share/${PN}-${PV}"
WINE_INCDIR="/usr/include/${PN}-${PV}"

QA_PREBUILT="*"

pkg_setup() {
	if use cpu_flags_x86_avx2; then
		MY_ARCH="x86_64_v3"
	else
		MY_ARCH="x86_64"
	fi
	MY_P="proton-cachyos-${MY_BASE}-${MY_DATE}-slr-${MY_ARCH}"
	S="${WORKDIR}/${MY_P}"
}

src_install() {
	dodir "${WINE_PREFIX}/bin"
	dodir "${WINE_PREFIX}/lib/wine"
	dodir "${WINE_PREFIX}/share/wine"
	dodir "${WINE_INCDIR}/wine"

	# Install binaries
	if [[ -d "${S}/files/bin" ]]; then
		exeinto "${WINE_PREFIX}/bin"
		doexe "${S}/files/bin"/*
	fi

	# Install wine libs to lib/wine/ (where the binary expects them)
	if [[ -d "${S}/files/lib/wine" ]]; then
		cp -a "${S}/files/lib/wine/"* "${ED}${WINE_PREFIX}/lib/wine/" || die
	fi

	# Create symlink wine -> lib/wine for eselect-wine compatibility
	dosym -r "${WINE_PREFIX}/lib/wine" "${WINE_PREFIX}/wine"

	# Install share data to prefix/share/wine (where binary expects ../share/wine)
	if [[ -d "${S}/files/share/wine" ]]; then
		cp -a "${S}/files/share/wine/"* "${ED}${WINE_PREFIX}/share/wine/" || die
	fi

	# Create share symlink for eselect-wine
	dosym -r "${WINE_PREFIX}/share" "${WINE_DATADIR}"

	keepdir "${WINE_INCDIR}/wine"

	# Create variant wrappers for eselect-wine
	local bin
	for bin in "${ED}${WINE_PREFIX}/bin"/*; do
		[[ -f ${bin} && -x ${bin} ]] || continue
		local binname="${bin##*/}"
		make_wrapper "${binname}-${PN#wine-}-${PV}" "${WINE_PREFIX}/bin/${binname}"
	done
}

pkg_postinst() {
	eselect wine update --if-unset

	local arch_info
	use cpu_flags_x86_avx2 && arch_info="AVX2 (v3)" || arch_info="baseline"

	elog "To select: eselect wine set ${PN}-${PV}"
	elog "Optimized for: ${arch_info}"
	elog ""
	elog "NTSync (kernel 6.14+):"
	elog "  modprobe ntsync && PROTON_USE_NTSYNC=1"
	elog ""
	elog "NOTE: This is a prebuilt binary package. If you see a"
	elog "preserved-rebuild loop (e.g. after upgrading ffmpeg),"
	elog "it is safe to ignore -- the preserved libraries will"
	elog "continue to work until the next wine-cachyos release."
}

pkg_postrm() {
	eselect wine update --if-unset
}
