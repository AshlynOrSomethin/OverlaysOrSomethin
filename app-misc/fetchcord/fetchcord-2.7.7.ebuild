EAPI=8

# FetchCord is a Python package
PYTHON_COMPAT=( python3_{10..13} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 systemd

DESCRIPTION="FetchCord grabs your OS info and displays it as Discord Rich Presence"
HOMEPAGE="https://github.com/MrPotatoBobx/fetchcord"
LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

# Upstream PKGBUILD uses the testing branch
# Using git-r3 to fetch that branch
EGIT_REPO_URI="https://github.com/MrPotatoBobx/fetchcord.git"
EGIT_BRANCH="testing"

# Runtime deps (Arch: neofetch, python-psutil; python itself is implied via distutils)
RDEPEND="
  app-misc/neofetch
  dev-python/psutil[${PYTHON_USEDEP}]
"
# Build-time deps
BDEPEND="
  dev-python/setuptools[${PYTHON_USEDEP}]
  dev-vcs/git
"

# We use git, so no SRC_URI; git-r3 handles fetch/unpack
inherit git-r3

# Use PEP517 build backend if upstream supports it; default to setuptools
DISTUTILS_USE_PEP517=setuptools

# Respect upstream version (PKGBUILD computed a rolling rN.hash). In Gentoo,
# we keep the version as provided; live ebuilds usually are -9999.
# If you want an auto-generated version, consider a -9999 ebuild instead.

src_prepare() {
  default
  # Nothing special to patch; setup.py handles build
}

python_install_all() {
  # Docs: install only if present
  [[ -e README ]]      && dodoc README
  [[ -e README.md ]]   && dodoc README.md
  [[ -e README.rst ]]  && dodoc README.rst
  [[ -e CHANGELOG ]]   && dodoc CHANGELOG
  [[ -e CHANGELOG.md ]] && dodoc CHANGELOG.md
  [[ -e LICENSE ]]     && dodoc LICENSE

  # Install user systemd unit if present
  if [[ -f systemd/fetchcord.service ]]; then
    systemd_douserunit systemd/fetchcord.service
  fi

  distutils-r1_python_install_all
}
