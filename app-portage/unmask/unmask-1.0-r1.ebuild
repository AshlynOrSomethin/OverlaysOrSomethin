EAPI=8

DESCRIPTION="Helper that adds ~amd64 package.accept_keywords entries"
HOMEPAGE="https://github.com/AshlynOrSomethin/gentoo-unmask"
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"
S="${WORKDIR}"

src_install() {
    newbin "${FILESDIR}/${PN}" unmask
}