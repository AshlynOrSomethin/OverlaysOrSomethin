# Copyright 2023-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson tmpfiles

DESCRIPTION="Modular initramfs image creation utility"
HOMEPAGE="https://gitlab.archlinux.org/archlinux/mkinitcpio/mkinitcpio"

ARCH_PKGVER=${PV%.*}
ARCH_PKGREL=${PV##*.}

SRC_URI="https://sources.archlinux.org/other/${PN}/${PN}-${ARCH_PKGVER}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+systemd"

COMMON_DEPEND="
	app-alternatives/awk
	app-arch/libarchive
	app-arch/zstd
	sys-apps/baselayout
	sys-devel/binutils
	sys-apps/coreutils
	sys-apps/diffutils
	sys-apps/findutils
	sys-apps/grep
	sys-apps/kmod
	sys-apps/util-linux
	sys-apps/busybox
	virtual/udev
"

DEPEND="${COMMON_DEPEND}"
RDEPEND="
	${COMMON_DEPEND}
	systemd? ( sys-apps/systemd )
"

S="${WORKDIR}/${PN}-${ARCH_PKGVER}"

QA_PREBUILT="/usr/lib/initcpio/busybox"

src_prepare() {
	default
}

src_configure() {
	local emesonargs=(
		$(meson_feature systemd systemd)
		-Dsystemd_hooks=$(usex systemd true false)
		-Dkernel_install=false
		-Dalpm=false
		-Ddocs=false
	)
	meson_src_configure
}

src_install() {
	meson_src_install

	exeinto /usr/lib/initcpio/
	doexe /bin/busybox

	cat > "${T}/linux.preset" <<'EOF' || die
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz"

PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
default_image="/boot/initramfs.img"
#default_options=""

#fallback_config="/etc/mkinitcpio.conf"
fallback_image="/boot/initramfs-fallback.img"
fallback_options="-S autodetect"
EOF

	insinto /etc/mkinitcpio.d
	newins "${T}/linux.preset" linux.preset
}

pkg_postinst() {
	tmpfiles_process 20-mkinitcpio.conf
}
