EAPI=8

inherit xdg-utils

DESCRIPTION="NBTExplorer binary package for editing Minecraft NBT files"
HOMEPAGE="https://github.com/jaquadro/NBTExplorer"
SRC_URI="amd64? ( https://github.com/jaquadro/NBTExplorer/releases/download/v${PV}-win/NBTExplorer-${PV}.zip -> ${P}.zip )"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

RDEPEND="dev-lang/mono"

S="${WORKDIR}"
QA_PREBUILT="*"

src_install() {
  insinto /usr/share/nbtexplorer
  doins NBTExplorer.exe NBTExplorer.exe.config Substrate.dll NBTModel.dll || die

  cat > "${T}/nbtexplorer" <<'EOF' || die
#!/bin/sh
exec mono /usr/share/nbtexplorer/NBTExplorer.exe "$@"
EOF
  dobin "${T}/nbtexplorer"

  cat > "${T}/nbtexplorer.desktop" <<'EOF' || die
[Desktop Entry]
Name=NBTExplorer
GenericName=NBTExplorer
Comment=A Minecraft NBT file editor for editing world and player files
Exec=/usr/bin/nbtexplorer %F
Icon=nbtexplorer
Terminal=false
Type=Application
Categories=Game;
EOF
  insinto /usr/share/applications
  doins "${T}/nbtexplorer.desktop"
}

pkg_postinst() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
}

pkg_postrm() {
  type update_desktop_database >/dev/null 2>&1 && update_desktop_database
}
