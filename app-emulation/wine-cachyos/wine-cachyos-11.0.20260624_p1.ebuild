# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools wrapper

COMMIT_STAGING="8d29c562d31e84b2817305c0f576832207e39578"
COMMIT_NATIVE="80163bd5856d34f53ed018abfae8d00a26b54c54"
SRC_URI="
	staging? ( https://github.com/CachyOS/wine-cachyos/archive/${COMMIT_STAGING}.tar.gz -> ${P}-staging.tar.gz )
	native?  ( https://github.com/CachyOS/wine-cachyos/archive/${COMMIT_NATIVE}.tar.gz -> ${P}-native.tar.gz )
"

DESCRIPTION="CachyOS Wine source snapshot (staging/native branches)"
HOMEPAGE="https://github.com/CachyOS/wine-cachyos"

IUSE="+staging native abi_x86_32 +abi_x86_64 cpu_flags_x86_avx2 cpu_flags_x86_avx512f"
REQUIRED_USE="
	^^ ( staging native )
	|| ( abi_x86_32 abi_x86_64 )
	cpu_flags_x86_avx512f? ( cpu_flags_x86_avx2 )
"

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
	abi_x86_32? (
		dev-libs/glib:2[abi_x86_32]
		media-libs/alsa-lib[abi_x86_32]
		media-libs/fontconfig[abi_x86_32]
		media-libs/freetype:2[abi_x86_32]
		media-libs/libglvnd[abi_x86_32]
		net-libs/gnutls[abi_x86_32]
		sys-libs/zlib[abi_x86_32]
		x11-libs/libX11[abi_x86_32]
		x11-libs/libXext[abi_x86_32]
	)
"

DEPEND="
	${RDEPEND}
	sys-devel/bison
	sys-devel/flex
	sys-devel/gettext
	virtual/pkgconfig
"

pkg_setup() {
	if use staging; then
		COMMIT="${COMMIT_STAGING}"
	else
		COMMIT="${COMMIT_NATIVE}"
	fi

	S="${WORKDIR}/${PN}-${COMMIT}"
}

src_prepare() {
	default

	# GitHub source archives do not include generated configure scripts.
	eautoreconf
}

src_configure() {
	local mycflags="${CFLAGS}"
	use cpu_flags_x86_avx2 && mycflags+=" -mavx2"
	use cpu_flags_x86_avx512f && mycflags+=" -mavx512f"

	mkdir -p build || die
	pushd build >/dev/null || die
	CFLAGS="${mycflags}" econf \
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
	local branch commit
	if use staging; then
		branch="cachyos_11.0_release/_staging"
		commit="${COMMIT_STAGING}"
	else
		branch="cachyos_11.0_release/_native"
		commit="${COMMIT_NATIVE}"
	fi

	einfo "Installed snapshot commit: ${commit:0:12} from ${branch}"
	einfo "Launch with: wine-cachyos"
}
