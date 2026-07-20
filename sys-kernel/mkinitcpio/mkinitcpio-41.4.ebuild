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

	# Keep behavior aligned with Arch pkgrel=4 fixes for mkinitcpio 41.
	if [[ ${PV} == 41.4 ]]; then
		cat > "${T}/${P}-pkgrel4.patch" <<'EOF' || die
diff --git a/install/systemd b/install/systemd
index c40f0a0..e85a5f6 100644
--- a/install/systemd
+++ b/install/systemd
@@ -193,9 +193,11 @@ build() {
	add_file "/usr/lib/tmpfiles.d/20-systemd-stub.conf"

	# add hwdb binaries to the initramfs
-    map add_file \
-        /usr/lib/udev/hwdb.bin \
-        /etc/udev/hwdb.bin
+    for f in /usr/lib/udev/hwdb.bin /etc/udev/hwdb.bin; do
+        if [[ -f "$f" ]]; then
+            add_file "$f"
+        fi
+    done

	# Include nvpcr files
	for nvpcr in /usr/lib/nvpcr/*.nvpcr; do
diff --git a/install/udev b/install/udev
index 33ed07b..9e1fb74 100644
--- a/install/udev
+++ b/install/udev
@@ -21,9 +21,11 @@ build() {
	    '80-drivers.rules'

	# add hwdb binaries to the initramfs
-    map add_file \
-        /usr/lib/udev/hwdb.bin \
-        /etc/udev/hwdb.bin
+    for f in /usr/lib/udev/hwdb.bin /etc/udev/hwdb.bin; do
+        if [[ -f "$f" ]]; then
+            add_file "$f"
+        fi
+    done

	add_runscript
 }
diff --git a/install/sd-encrypt b/install/sd-encrypt
index 856f640..684d6e3 100644
--- a/install/sd-encrypt
+++ b/install/sd-encrypt
@@ -36,12 +36,14 @@ build() {
	add_binary '/usr/lib/ossl-modules/legacy.so'

	# add libraries dlopen()ed by systemd-cryptsetup
-    LC_ALL=C.UTF-8 find /usr/lib/ -maxdepth 1 -name "libfido2.so*" | while read -r FILE; do
-        if [[ -L "${FILE}" ]]; then
-            add_symlink "${FILE}"
-        else
-            add_binary "${FILE}"
-        fi
+    for LIB in fido2 cryptsetup; do
+        LC_ALL=C.UTF-8 find /usr/lib/ -maxdepth 1 -name "lib${LIB}.so*" | while read -r FILE; do
+            if [[ -L "${FILE}" ]]; then
+                add_symlink "${FILE}"
+            else
+                add_binary "${FILE}"
+            fi
+        done
	done

	# add mkswap for creating swap space on the fly (see 'swap' in crypttab(5))
EOF
		eapply "${T}/${P}-pkgrel4.patch"
	fi
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
	tmpfiles_process
}
