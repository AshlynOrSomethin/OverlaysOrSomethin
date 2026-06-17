EAPI=8

inherit unpacker

DESCRIPTION="Brother LPR and CUPS driver for HLL2305"
HOMEPAGE="http://support.brother.com/g/s/id/linux/en"
MY_PV_BASE="3.2.0"
MY_PV_REL="1"
SRC_URI="
  amd64? (
    http://download.brother.com/welcome/dlf101902/hll2305lpr-${MY_PV_BASE}-${MY_PV_REL}.i386.rpm -> hll2305lpr-${MY_PV_BASE}-${MY_PV_REL}.i386.rpm
    http://download.brother.com/welcome/dlf101903/hll2305cupswrapper-${MY_PV_BASE}-${MY_PV_REL}.i386.rpm -> hll2305cupswrapper-${MY_PV_BASE}-${MY_PV_REL}.i386.rpm
  )
"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="strip mirror"

RDEPEND="
  net-print/cups
  app-text/ghostscript-gpl
"

S="${WORKDIR}"
QA_PREBUILT="*"

src_unpack() {
  for rpm in "hll2305lpr-${MY_PV_BASE}-${MY_PV_REL}.i386.rpm" "hll2305cupswrapper-${MY_PV_BASE}-${MY_PV_REL}.i386.rpm"; do
    ( cd "${WORKDIR}" && rpm2cpio "${DISTDIR}/${rpm}" 2>/dev/null | cpio -id 2>/dev/null ) || \
    ( cd "${WORKDIR}" && bsdtar -xf "${DISTDIR}/${rpm}" ) || die "Failed to extract ${rpm}"
  done
}

src_prepare() {
  default

  local wrap="opt/brother/Printers/HLL2305/cupswrapper/brother_lpdwrapper_HLL2305"
  [[ -f ${wrap} ]] || die "Expected wrapper script missing"

  sed -i \
    -e 's|^\(my \$PRINTER\)=\$basedir;|#\1=$basedir;|' \
    -e 's|^\(\$PRINTER =~ s/\^\\/opt\\/\.\*\\/Printers\\///g;\)|#\1|' \
    -e 's|^\(\$PRINTER =~ s/\\/cupswrapper//g;\)|#\1|' \
    -e 's|^\(\$PRINTER =~ s/\\///g;\)|#\1|' \
    -e 's|\$lpddir = \$basedir\."/lpd/";|$lpddir = $basedir."/lpd";|' \
    "${wrap}" || die

  if ! grep -q 'my \$PRINTER = "HLL2305";' "${wrap}"; then
    sed -i '/^#my \$PRINTER=\$basedir;/a my \$PRINTER = "HLL2305";\nmy \$basedir = "/usr/share/Brother/Printer/$PRINTER";' "${wrap}" || die
  fi
}

src_install() {
  if [[ -d var ]]; then
    cp -a var "${D}"/ || die
  fi

  insinto /usr/share/cups/model
  newins opt/brother/Printers/HLL2305/cupswrapper/brother-HLL2305-cups-en.ppd brother-HLL2305-cups-en.ppd

  exeinto /usr/libexec/cups/filter
  newexe opt/brother/Printers/HLL2305/cupswrapper/brother_lpdwrapper_HLL2305 brother_lpdwrapper_HLL2305

  insinto /usr/share/Brother/Printer/HLL2305/cupswrapper
  doins opt/brother/Printers/HLL2305/cupswrapper/paperconfigml1
}
