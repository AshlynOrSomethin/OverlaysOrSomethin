EAPI=8

inherit go-module optfeature shell-completion systemd xdg

DESCRIPTION="File manager for the dux desktop, built with Quickshell and Go"
HOMEPAGE="https://github.com/duxlabs-dev/dux-files"
SRC_URI="https://github.com/duxlabs-dev/dux-files/releases/download/v${PV}/dfiles-${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/dfiles-${PV}"

# dux-files is MIT, the rest is the vendored Go modules shipped in the release tarball
LICENSE="MIT Apache-2.0 BSD BSD-2 ISC MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"
RESTRICT="mirror"

RDEPEND="
  gui-apps/quickshell[wayland]
  sys-auth/polkit
"
BDEPEND=">=dev-lang/go-1.27"

src_compile() {
  # Copies the Quickshell UI into core/internal/shellembed/dist for go:embed
  emake -C core sync-shell

  cd core || die
  CGO_ENABLED=0 ego build -mod=vendor -tags withshell -trimpath \
    -ldflags "-X main.Version=${PV}" \
    -o dfiles ./cmd/dfiles

  ./dfiles completion bash > dfiles.bash || die
  ./dfiles completion zsh > _dfiles || die
  ./dfiles completion fish > dfiles.fish || die
}

src_test() {
  cd core || die
  # Racy upstream fixture: the entry index is invalidated by directory mtime,
  # so .desktop files written within one kernel timestamp tick are missed
  CGO_ENABLED=0 ego test -mod=vendor -skip TestSectionsCapsRecentAtFive ./...
}

src_install() {
  dobin core/dfiles

  newbashcomp core/dfiles.bash dfiles
  dozshcomp core/_dfiles
  dofishcomp core/dfiles.fish

  domenu assets/dev.duxlabs.files.desktop
  doicon -s scalable assets/dev.duxlabs.files.svg

  insinto /usr/share/metainfo
  doins assets/dev.duxlabs.files.metainfo.xml

  insinto /usr/share/polkit-1/actions
  doins assets/dev.duxlabs.files.policy

  # org.freedesktop.FileManager1 and the portal file chooser backend
  insinto /usr/share/dbus-1/services
  doins assets/dbus/*.service
  insinto /usr/share/xdg-desktop-portal/portals
  doins assets/portal/dfiles.portal

  use systemd && systemd_douserunit assets/systemd/dfiles.service

  dodoc README.md CHANGELOG.md
}

pkg_postinst() {
  xdg_pkg_postinst

  optfeature "running external thumbnailers in a sandbox" sys-apps/bubblewrap
  optfeature "video thumbnails" media-video/ffmpegthumbnailer
  optfeature "PDF thumbnails" app-text/poppler
  optfeature "network shares and the trash on removable drives" gnome-base/gvfs
  optfeature "the devices sidebar" sys-fs/udisks
  optfeature "faster recursive search" gui-apps/danksearch

  elog "Run 'dfiles show' or launch Files from your application menu."
  elog "To open folders here by default:"
  elog "  xdg-mime default dev.duxlabs.files.desktop inode/directory"
  elog "To serve other apps' open and save dialogs: dfiles portal install"
}
