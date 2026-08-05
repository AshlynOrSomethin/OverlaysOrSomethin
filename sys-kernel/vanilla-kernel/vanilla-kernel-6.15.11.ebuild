# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KERNEL_IUSE_GENERIC_UKI=1

inherit kernel-build toolchain-funcs

BASE_P=linux-${PV%.*}
# https://koji.fedoraproject.org/koji/packageinfo?packageID=8
# forked to git.gentoo.org:fork/fedora/kernel
CONFIG_VER=6.18.12-gentoo
GENTOO_CONFIG_P=gentoo-kernel-config-g19

DESCRIPTION="Linux kernel built from vanilla upstream sources"
HOMEPAGE="
	https://wiki.gentoo.org/wiki/Project:Distribution_Kernel
	https://www.kernel.org/
"
SRC_URI="
	https://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/${BASE_P}.tar.xz
	https://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/patch-${PV}.xz
	https://gitweb.gentoo.org/proj/dist-kernel/gentoo-kernel-config.git/snapshot/${GENTOO_CONFIG_P}.tar.bz2
	https://gitweb.gentoo.org/fork/fedora/kernel.git/snapshot/kernel-${CONFIG_VER}.tar.bz2
"
S=${WORKDIR}/${BASE_P}

KEYWORDS="~amd64"
IUSE="debug hardened"

BDEPEND="
	debug? ( dev-util/pahole )
"
PDEPEND="
	>=virtual/dist-kernel-${PV}
"

QA_FLAGS_IGNORED="
	usr/src/linux-.*/scripts/gcc-plugins/.*.so
	usr/src/linux-.*/vmlinux
	usr/src/linux-.*/arch/powerpc/kernel/vdso.*/vdso.*.so.dbg
"

src_prepare() {
	eapply "${WORKDIR}/patch-${PV}"
	default

	cp "${WORKDIR}/kernel-${CONFIG_VER}/kernel-x86_64-fedora.config" .config || die

	local myversion="-dist"
	use hardened && myversion+="-hardened"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${T}"/version.config || die
	local dist_conf_path="${WORKDIR}/${GENTOO_CONFIG_P}"

	local merge_configs=(
		"${T}"/version.config
		"${dist_conf_path}"/base.config
		"${dist_conf_path}"/6.12+.config
	)
	use debug || merge_configs+=(
		"${dist_conf_path}"/no-debug.config
	)
	if use hardened; then
		merge_configs+=( "${dist_conf_path}"/hardened-base.config )
		tc-is-gcc && merge_configs+=( "${dist_conf_path}"/hardened-gcc-plugins.config )
	fi

	# Avoid building resolve_btfids/libbpf on older kernel branches with newer compilers.
	cat > "${T}"/no-btf.config <<-EOF || die
		CONFIG_DEBUG_INFO_BTF=n
		CONFIG_DEBUG_INFO_BTF_MODULES=n
	EOF
	merge_configs+=( "${T}"/no-btf.config )

	kernel-build_merge_configs "${merge_configs[@]}"
}

src_configure() {
	# Older stable kernels can fail host-tool builds on newer compilers due to -Werror.
	export HOSTCFLAGS="${HOSTCFLAGS} -Wno-error"
	export HOSTCXXFLAGS="${HOSTCXXFLAGS} -Wno-error"
	kernel-build_src_configure
}
