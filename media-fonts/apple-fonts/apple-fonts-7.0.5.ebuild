EAPI=8

inherit font

DESCRIPTION="Fonts for Apple platforms, including San Francisco and New York"
HOMEPAGE="https://developer.apple.com/fonts/"
SRC_URI="
  https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg -> SF-Pro-${PV}.dmg
  https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg -> SF-Compact-${PV}.dmg
  https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg -> SF-Mono-${PV}.dmg
  https://devimages-cdn.apple.com/design/resources/download/NY.dmg -> NY-${PV}.dmg
"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="bindist mirror"

BDEPEND="app-arch/p7zip"

S="${WORKDIR}"
FONT_S="${WORKDIR}/fonts"

src_unpack() {
  :
}

src_prepare() {
  default

  local dmg pkgfile pkgroot fontsfound
  local extract_dir="${T}/apple-fonts-extract"

  mkdir -p "${WORKDIR}/fonts" "${WORKDIR}/licenses" "${extract_dir}" || die

  for dmg in \
    "${DISTDIR}/SF-Pro-${PV}.dmg" \
    "${DISTDIR}/SF-Compact-${PV}.dmg" \
    "${DISTDIR}/SF-Mono-${PV}.dmg" \
    "${DISTDIR}/NY-${PV}.dmg"; do
    rm -rf "${extract_dir}"/* || die

    7z e "${dmg}" -y "-o${extract_dir}" >/dev/null || die "Failed to extract ${dmg}"

    pkgfile=$(find "${extract_dir}" -maxdepth 1 -type f -name '*.pkg' | head -n1)
    [[ -n ${pkgfile} ]] || die "No .pkg found in ${dmg}"

    pkgroot="${extract_dir}/pkg"
    rm -rf "${pkgroot}" || die
    mkdir -p "${pkgroot}" || die

    7z x -txar "${pkgfile}" -y "-o${pkgroot}" >/dev/null || die "Failed to unpack package archive in ${dmg}"

    while IFS= read -r -d '' lic; do
      cp -f "${lic}" "${WORKDIR}/licenses/$(basename "${dmg}" .dmg)-LICENSE.rtf" || die
      break
    done < <(find "${pkgroot}" -type f -path '*/Resources/English.lproj/License.rtf' -print0)

    while IFS= read -r -d '' payload; do
      7z x "${payload}" -y >/dev/null || die "Failed to extract payload in ${dmg}"
    done < <(find "${pkgroot}" -type f \( -name 'Payload' -o -name 'Payload~' \) -print0)

    fontsfound=0
    while IFS= read -r -d '' fontfile; do
      cp -f "${fontfile}" "${WORKDIR}/fonts/" || die
      fontsfound=1
    done < <(find "${pkgroot}" -type f \( -name '*.otf' -o -name '*.ttf' \) -path '*/Library/Fonts/*' -print0)

    [[ ${fontsfound} -eq 1 ]] || die "No fonts extracted from ${dmg}"
  done
}

src_install() {
  local suffixes=()

  compgen -G "${FONT_S}/*.otf" >/dev/null && suffixes+=(otf)
  compgen -G "${FONT_S}/*.ttf" >/dev/null && suffixes+=(ttf)
  [[ ${#suffixes[@]} -gt 0 ]] || die "No fonts found in ${FONT_S}"

  FONT_SUFFIX="${suffixes[*]}"
  font_src_install

  if compgen -G "${WORKDIR}/licenses/*" >/dev/null; then
    insinto "/usr/share/licenses/${PF}"
    doins "${WORKDIR}/licenses"/*
  fi
}
