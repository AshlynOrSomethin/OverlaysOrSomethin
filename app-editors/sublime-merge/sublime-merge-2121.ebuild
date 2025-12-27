# Copyright 2025
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Sublime Merge - a fast, intuitive Git client from the makers of Sublime Text"
HOMEPAGE="https://www.sublimemerge.com"
# upstream provides prebuilt tar.xz for x64 Linux
SRC_URI="https://download.sublimetext.com/sublime_merge_build_${PV}_x64.tar.xz -> ${P}-linux-x64.tar.xz"

# Upstream ships a custom license file
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="mirror strip bindist"  # prebuilt binary; do not strip

RDEPEND="
  x11-libs/gtk+:3
"
DEPEND=""

# The tarball extracts to sublime_merge/
S="${WORKDIR}/sublime_merge"

src_prepare() {
  default
  # Nothing to patch; just ensure desktop file is present
  if [[ ! -f sublime_merge.desktop ]]; then
    ewarn "sublime_merge.desktop not found in archive; continuing but desktop may not be installed."
  fi
}

src_install() {
  # Install main directory under /opt
  insinto /opt/sublime_merge
  doins -r \
    crash_handler \
    git-credential-sublime \
    ssh-askpass-sublime \
    sublime_merge \
    changelog.txt \
    Packages \
    Icon

  # Ensure main binary is executable
  fperms 0755 /opt/sublime_merge/sublime_merge
  fperms 0755 /opt/sublime_merge/crash_handler
  fperms 0755 /opt/sublime_merge/git-credential-sublime
  fperms 0755 /opt/sublime_merge/ssh-askpass-sublime

  # Create user-facing symlink smerge in /usr/bin
  dosym /opt/sublime_merge/sublime_merge /usr/bin/smerge

  # Icons: link to system hicolor theme
  local sz
  for sz in 256x256 128x128 48x48 32x32 16x16; do
    dodir /usr/share/icons/hicolor/${sz}/apps
    dosym /opt/sublime_merge/Icon/${sz}/sublime-merge.png \
      /usr/share/icons/hicolor/${sz}/apps/sublime-merge.png
  done

  # Desktop file (if present)
  if [[ -f "${S}/sublime_merge.desktop" ]]; then
    domenu "${S}/sublime_merge.desktop"
  fi

  # License
  if [[ -f "${WORKDIR}/LICENSE" ]]; then
    dodir /usr/share/licenses/${PF}
    doins "${WORKDIR}/LICENSE"
  elif [[ -f "${S}/LICENSE" ]]; then
    dodir /usr/share/licenses/${PF}
    doins "${S}/LICENSE"
  fi
}

pkg_postinst() {
  xdg_icon_cache_update
  xdg_desktop_database_update
}

pkg_postrm() {
  xdg_icon_cache_update
  xdg_desktop_database_update
}
