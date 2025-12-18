EAPI=8

inherit desktop

DESCRIPTION="Equibop is a fork of Vesktop (prebuilt Linux bundle)."
HOMEPAGE="https://github.com/Equicord/Equibop"
# Prebuilt x86_64 Linux tarball from the release assets
SRC_URI="https://github.com/Equicord/Equibop/releases/download/v${PV}/equibop-${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"

# No build tools needed; we just install the prebuilt bundle.
RESTRICT="strip"

# No build-time deps
BDEPEND=""
RDEPEND=""

# The tarball extracts into linux-unpacked with the binary 'equibop'
S="${WORKDIR}"

src_compile() {
	: # nothing to build
}

src_install() {
	# Install under /opt/equibop
	insinto /opt/equibop
	# The archive contains linux-unpacked/
	doins -r linux-unpacked || die "missing linux-unpacked in tarball"
	fperms +x /opt/equibop/linux-unpacked/equibop

	# Icon and desktop entry
	# Icon is inside resources of the app; fallback to static if present
	if [[ -f linux-unpacked/resources/app/static/icon.png ]]; then
		newicon linux-unpacked/resources/app/static/icon.png equibop.png
	elif [[ -f static/icon.png ]]; then
		newicon static/icon.png equibop.png
	fi

	make_desktop_entry /opt/equibop/linux-unpacked/equibop "Equibop" equibop \
		"Network;Chat;InstantMessaging;"

	# CLI convenience
	dosym /opt/equibop/linux-unpacked/equibop /usr/bin/equibop
}
