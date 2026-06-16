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

  local dmg fontsfound
  local extract_dir="${T}/apple-fonts-extract"

  mkdir -p "${WORKDIR}/fonts" "${WORKDIR}/licenses" "${extract_dir}" || die

  for dmg in \
    "${DISTDIR}/SF-Pro-${PV}.dmg" \
    "${DISTDIR}/SF-Compact-${PV}.dmg" \
    "${DISTDIR}/SF-Mono-${PV}.dmg" \
    "${DISTDIR}/NY-${PV}.dmg"; do
    rm -rf "${extract_dir}"/* || die

    7z e "${dmg}" -y "-o${extract_dir}" >/dev/null || die "Failed to extract ${dmg}"

    # Follow upstream AUR extraction flow closely for compatibility.
    pushd "${extract_dir}" >/dev/null || die

    7z x -txar ./*.pkg -y >/dev/null || die "Failed to unpack package archive in ${dmg}"

    while IFS= read -r -d '' lic; do
      cp -f "${lic}" "${WORKDIR}/licenses/$(basename "${dmg}" .dmg)-LICENSE.rtf" || die
      break
    done < <(find . -type f -path '*/Resources/English.lproj/License.rtf' -print0)

    fontsfound=0
    while IFS= read -r -d '' pkgdir; do
      pushd "${pkgdir}" >/dev/null || die

      if [[ -f Payload ]]; then
        7z x Payload -y >/dev/null || die "Failed to extract Payload in ${pkgdir}"
      fi
      if [[ -f Payload~ ]]; then
        7z x Payload~ -y >/dev/null || die "Failed to extract Payload~ in ${pkgdir}"
      fi

      while IFS= read -r -d '' fontfile; do
        cp -f "${fontfile}" "${WORKDIR}/fonts/" || die
        fontsfound=1
      done < <(find . -type f \( -name '*.otf' -o -name '*.ttf' \) -path '*/Library/Fonts/*' -print0)

      popd >/dev/null || die
    done < <(find . -maxdepth 2 -type d -name '*.pkg' -print0)

    popd >/dev/null || die

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
