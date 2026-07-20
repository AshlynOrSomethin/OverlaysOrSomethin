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

	# Gentoo compatibility: some systems do not ship hwdb.bin in Arch paths.
	sed -i \
		'/# add hwdb binaries to the initramfs/,/\/etc\/udev\/hwdb.bin/c\
    # add hwdb binaries to the initramfs when available\
    for f in /usr/lib/udev/hwdb.bin /etc/udev/hwdb.bin; do\
        [[ -f "$f" ]] && add_file "$f"\
    done' \
		install/systemd install/udev || die

	# Gentoo kernels may not provide both compression helper modules.
	sed -i \
		"s#map add_module 'crypto-lzo' 'crypto-lz4'#for mod in crypto-lzo crypto-lz4; do\\n        modinfo -k \"\$KERNELVERSION\" \"\$mod\" >/dev/null 2>\&1 \&\& add_module \"\$mod\"\\n    done#" \
		install/systemd || die

	# Keymap directory may be absent on minimal installs.
	sed -i \
		's#LC_ALL=C.UTF-8 find /usr/share/kbd/keymaps/#[[ -d /usr/share/kbd/keymaps ]] \&\& LC_ALL=C.UTF-8 find /usr/share/kbd/keymaps/#' \
		install/sd-vconsole || die
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
}

pkg_postinst() {
	tmpfiles_process 20-mkinitcpio.conf

	local cpu_vendor="" legacy_ucode="" expected_ucode=""
	if grep -aq 'AuthenticAMD' /proc/cpuinfo ; then
		cpu_vendor="amd"
		legacy_ucode="/boot/amd-uc.img"
		expected_ucode="/boot/amd-ucode.img"
	elif grep -aq 'GenuineIntel' /proc/cpuinfo ; then
		cpu_vendor="intel"
		legacy_ucode="/boot/intel-uc.img"
		expected_ucode="/boot/intel-ucode.img"
	fi

	# mkinitcpio's microcode hook looks for *-ucode.img in /boot as a fallback.
	if [[ -n ${expected_ucode} && ! -e ${expected_ucode} && -e ${legacy_ucode} ]]; then
		ln -sfn "${legacy_ucode##*/}" "${expected_ucode}" \
			&& einfo "Linked ${expected_ucode} -> ${legacy_ucode##*/} for mkinitcpio microcode autodetect" \
			|| ewarn "Failed to create ${expected_ucode} symlink; microcode fallback image autodetect may fail"
	fi

	if [[ -f /etc/mkinitcpio.d/linux.preset ]] \
		&& grep -q '^ALL_kver="/boot/vmlinuz"$' /etc/mkinitcpio.d/linux.preset \
		&& [[ ! -r /boot/vmlinuz ]]; then
		rm -f /etc/mkinitcpio.d/linux.preset || die
		einfo "Removed stale legacy preset /etc/mkinitcpio.d/linux.preset"
	fi

	mkdir -p /etc/mkinitcpio.d || die

	local kernel kernel_name kernel_ver preset_file generated=0
	for kernel in /boot/kernel-*; do
		[[ -f ${kernel} ]] || continue
		kernel_name=${kernel##*/}
		kernel_ver=${kernel_name#kernel-}
		preset_file="/etc/mkinitcpio.d/${kernel_ver}.preset"

		cat > "${preset_file}" <<-EOF || die
		ALL_config="/etc/mkinitcpio.conf"
		ALL_kver="${kernel}"

		PRESETS=('default' 'fallback')

		default_image="/boot/initramfs-${kernel_ver}.img"
		fallback_image="/boot/initramfs-${kernel_ver}-fallback.img"
		fallback_options="-S autodetect"
		EOF

		generated=$((generated + 1))
		einfo "Generated mkinitcpio preset: ${preset_file}"
	done

	if (( generated == 0 )); then
		ewarn "No /boot/kernel-* files were found; no mkinitcpio presets were generated"
	else
		einfo "Generated ${generated} kernel preset(s). Run: mkinitcpio -P"
	fi
}
