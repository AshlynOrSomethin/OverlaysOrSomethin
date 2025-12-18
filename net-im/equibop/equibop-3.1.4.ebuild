EAPI=8

inherit desktop

DESCRIPTION="Equibop is a fork of Vesktop (prebuilt Linux x86_64 bundle)."
HOMEPAGE="https://github.com/Equicord/Equibop"
# IMPORTANT: This is the prebuilt Linux x86_64 tarball from Releases (not source code)
SRC_URI="https://github.com/Equicord/Equibop/releases/download/v${PV}/equibop-${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip"

S=${WORKDIR}

src_compile() { :; }

src_install() {
	# This prebuilt tar extracts to linux-unpacked/ with the 'equibop' binary
	if [[ ! -d ${S}/linux-unpacked ]]; then
		die "Expected linux-unpacked/ in release tarball; got: $(ls -1 ${S})"
	fi
	insinto /opt/equibop
	doins -r linux-unpacked || die "installing linux-unpacked failed"

	fperms +x /opt/equibop/linux-unpacked/equibop

	# Icon path inside bundle
	if [[ -f linux-unpacked/resources/app/static/icon.png ]]; then
		newicon linux-unpacked/resources/app/static/icon.png equibop.png
	fi

	dosym /opt/equibop/linux-unpacked/equibop /usr/bin/equibop
	make_desktop_entry /usr/bin/equibop "Equibop" equibop "Network;Chat;InstantMessaging;"
}
