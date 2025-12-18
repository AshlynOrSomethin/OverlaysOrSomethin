# Copyright 2021-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit font check-reqs

DESCRIPTION="Nerd Fonts is a project that patches developer targeted fonts with glyphs"
HOMEPAGE="https://github.com/ryanoasis/nerd-fonts"
COMMON_URI="https://github.com/ryanoasis/${PN}/releases/download/v3.4.0"
TAG_URI="https://github.com/ryanoasis/nerd-fonts/raw/v3.4.0"

# Fetch only from upstream release URLs; skip Gentoo mirrors
RESTRICT="mirror"

FONTS=(
  0xProto
  3270
  AdwaitaMono
  Agave
  AnonymousPro
  Arimo
  AtkinsonHyperlegibleMono
  AurulentSansMono
  BigBlueTerminal
  BitstreamVeraSansMono
  CascadiaCode
  CascadiaMono
  CodeNewRoman
  ComicShannsMono
  CommitMono
  Cousine
  D2Coding
  DaddyTimeMono
  DejaVuSansMono
  DepartureMono
  DroidSansMono
  EnvyCodeR
  FantasqueSansMono
  FiraCode
  FiraMono
  GeistMono
  Go-Mono
  Gohu
  Hack
  Hasklig
  HeavyData
  Hermit
  iA-Writer
  IBMPlexMono
  Inconsolata
  InconsolataGo
  InconsolataLGC
  IntelOneMono
  Iosevka
  IosevkaTerm
  IosevkaTermSlab
  JetBrainsMono
  Lekton
  LiberationMono
  Lilex
  MartianMono
  Meslo
  Monaspace
  Monofur
  Monoid
  Mononoki
  MPlus
  NerdFontsSymbolsOnly
  Noto
  OpenDyslexic
  Overpass
  ProFont
  ProggyClean
  Recursive
  RobotoMono
  ShareTechMono
  SourceCodePro
  SpaceMono
  Terminus
  Tinos
  Ubuntu
  UbuntuMono
  UbuntuSans
  VictorMono
  ZedMono
)

SRC_URI="
  0xproto? ( ${COMMON_URI}/0xProto.tar.xz -> 0xProto-nf-3.4.0.tar.xz )
  3270? ( ${COMMON_URI}/3270.tar.xz -> 3270-nf-3.4.0.tar.xz )
  adwaitamono? ( ${COMMON_URI}/AdwaitaMono.tar.xz -> AdwaitaMono-nf-3.4.0.tar.xz )
  agave? ( ${COMMON_URI}/Agave.tar.xz -> Agave-nf-3.4.0.tar.xz )
  anonymouspro? ( ${COMMON_URI}/AnonymousPro.tar.xz -> AnonymousPro-nf-3.4.0.tar.xz )
  arimo? ( ${COMMON_URI}/Arimo.tar.xz -> Arimo-nf-3.4.0.tar.xz )
  atkinsonhyperlegiblemono? ( ${COMMON_URI}/AtkinsonHyperlegibleMono.tar.xz -> AtkinsonHyperlegibleMono-nf-3.4.0.tar.xz )
  aurulentsansmono? ( ${COMMON_URI}/AurulentSansMono.tar.xz -> AurulentSansMono-nf-3.4.0.tar.xz )
  bigblueterminal? ( ${COMMON_URI}/BigBlueTerminal.tar.xz -> BigBlueTerminal-nf-3.4.0.tar.xz )
  bitstreamverasansmono? ( ${COMMON_URI}/BitstreamVeraSansMono.tar.xz -> BitstreamVeraSansMono-nf-3.4.0.tar.xz )
  cascadiacode? ( ${COMMON_URI}/CascadiaCode.tar.xz -> CascadiaCode-nf-3.4.0.tar.xz )
  cascadiamono? ( ${COMMON_URI}/CascadiaMono.tar.xz -> CascadiaMono-nf-3.4.0.tar.xz )
  codenewroman? ( ${COMMON_URI}/CodeNewRoman.tar.xz -> CodeNewRoman-nf-3.4.0.tar.xz )
  comicshannsmono? ( ${COMMON_URI}/ComicShannsMono.tar.xz -> ComicShannsMono-nf-3.4.0.tar.xz )
  commitmono? ( ${COMMON_URI}/CommitMono.tar.xz -> CommitMono-nf-3.4.0.tar.xz )
  cousine? ( ${COMMON_URI}/Cousine.tar.xz -> Cousine-nf-3.4.0.tar.xz )
  d2coding? ( ${COMMON_URI}/D2Coding.tar.xz -> D2Coding-nf-3.4.0.tar.xz )
  daddytimemono? ( ${COMMON_URI}/DaddyTimeMono.tar.xz -> DaddyTimeMono-nf-3.4.0.tar.xz )
  dejavusansmono? ( ${COMMON_URI}/DejaVuSansMono.tar.xz -> DejaVuSansMono-nf-3.4.0.tar.xz )
  departuremono? ( ${COMMON_URI}/DepartureMono.tar.xz -> DepartureMono-nf-3.4.0.tar.xz )
  droidsansmono? ( ${COMMON_URI}/DroidSansMono.tar.xz -> DroidSansMono-nf-3.4.0.tar.xz )
  envycoder? ( ${COMMON_URI}/EnvyCodeR.tar.xz -> EnvyCodeR-nf-3.4.0.tar.xz )
  fantasquesansmono? ( ${COMMON_URI}/FantasqueSansMono.tar.xz -> FantasqueSansMono-nf-3.4.0.tar.xz )
  firacode? ( ${COMMON_URI}/FiraCode.tar.xz -> FiraCode-nf-3.4.0.tar.xz )
  firamono? ( ${COMMON_URI}/FiraMono.tar.xz -> FiraMono-nf-3.4.0.tar.xz )
  geistmono? ( ${COMMON_URI}/GeistMono.tar.xz -> GeistMono-nf-3.4.0.tar.xz )
  go-mono? ( ${COMMON_URI}/Go-Mono.tar.xz -> Go-Mono-nf-3.4.0.tar.xz )
  gohu? ( ${COMMON_URI}/Gohu.tar.xz -> Gohu-nf-3.4.0.tar.xz )
  hack? ( ${COMMON_URI}/Hack.tar.xz -> Hack-nf-3.4.0.tar.xz )
  hasklig? ( ${COMMON_URI}/Hasklig.tar.xz -> Hasklig-nf-3.4.0.tar.xz )
  heavydata? ( ${COMMON_URI}/HeavyData.tar.xz -> HeavyData-nf-3.4.0.tar.xz )
  hermit? ( ${COMMON_URI}/Hermit.tar.xz -> Hermit-nf-3.4.0.tar.xz )
  ia-writer? ( ${COMMON_URI}/iA-Writer.tar.xz -> iA-Writer-nf-3.4.0.tar.xz )
  ibmplexmono? ( ${COMMON_URI}/IBMPlexMono.tar.xz -> IBMPlexMono-nf-3.4.0.tar.xz )
  inconsolata? ( ${COMMON_URI}/Inconsolata.tar.xz -> Inconsolata-nf-3.4.0.tar.xz )
  inconsolatago? ( ${COMMON_URI}/InconsolataGo.tar.xz -> InconsolataGo-nf-3.4.0.tar.xz )
  inconsolatalgc? ( ${COMMON_URI}/InconsolataLGC.tar.xz -> InconsolataLGC-nf-3.4.0.tar.xz )
  intelonemono? ( ${COMMON_URI}/IntelOneMono.tar.xz -> IntelOneMono-nf-3.4.0.tar.xz )
  iosevka? ( ${COMMON_URI}/Iosevka.tar.xz -> Iosevka-nf-3.4.0.tar.xz )
  iosevkaterm? ( ${COMMON_URI}/IosevkaTerm.tar.xz -> IosevkaTerm-nf-3.4.0.tar.xz )
  iosevkatermslab? ( ${COMMON_URI}/IosevkaTermSlab.tar.xz -> IosevkaTermSlab-nf-3.4.0.tar.xz )
  jetbrainsmono? ( ${COMMON_URI}/JetBrainsMono.tar.xz -> JetBrainsMono-nf-3.4.0.tar.xz )
  lekton? ( ${COMMON_URI}/Lekton.tar.xz -> Lekton-nf-3.4.0.tar.xz )
  liberationmono? ( ${COMMON_URI}/LiberationMono.tar.xz -> LiberationMono-nf-3.4.0.tar.xz )
  lilex? ( ${COMMON_URI}/Lilex.tar.xz -> Lilex-nf-3.4.0.tar.xz )
  martianmono? ( ${COMMON_URI}/MartianMono.tar.xz -> MartianMono-nf-3.4.0.tar.xz )
  meslo? ( ${COMMON_URI}/Meslo.tar.xz -> Meslo-nf-3.4.0.tar.xz )
  monaspace? ( ${COMMON_URI}/Monaspace.tar.xz -> Monaspace-nf-3.4.0.tar.xz )
  monofur? ( ${COMMON_URI}/Monofur.tar.xz -> Monofur-nf-3.4.0.tar.xz )
  monoid? ( ${COMMON_URI}/Monoid.tar.xz -> Monoid-nf-3.4.0.tar.xz )
  mononoki? ( ${COMMON_URI}/Mononoki.tar.xz -> Mononoki-nf-3.4.0.tar.xz )
  mplus? ( ${COMMON_URI}/MPlus.tar.xz -> MPlus-nf-3.4.0.tar.xz )
  nerdfontssymbolsonly? ( ${COMMON_URI}/NerdFontsSymbolsOnly.tar.xz -> NerdFontsSymbolsOnly-nf-3.4.0.tar.xz )
  noto? ( ${COMMON_URI}/Noto.tar.xz -> Noto-nf-3.4.0.tar.xz )
  opendyslexic? ( ${COMMON_URI}/OpenDyslexic.tar.xz -> OpenDyslexic-nf-3.4.0.tar.xz )
  overpass? ( ${COMMON_URI}/Overpass.tar.xz -> Overpass-nf-3.4.0.tar.xz )
  profont? ( ${COMMON_URI}/ProFont.tar.xz -> ProFont-nf-3.4.0.tar.xz )
  proggyclean? ( ${COMMON_URI}/ProggyClean.tar.xz -> ProggyClean-nf-3.4.0.tar.xz )
  recursive? ( ${COMMON_URI}/Recursive.tar.xz -> Recursive-nf-3.4.0.tar.xz )
  robotomono? ( ${COMMON_URI}/RobotoMono.tar.xz -> RobotoMono-nf-3.4.0.tar.xz )
  sharetechmono? ( ${COMMON_URI}/ShareTechMono.tar.xz -> ShareTechMono-nf-3.4.0.tar.xz )
  sourcecodepro? ( ${COMMON_URI}/SourceCodePro.tar.xz -> SourceCodePro-nf-3.4.0.tar.xz )
  spacemono? ( ${COMMON_URI}/SpaceMono.tar.xz -> SpaceMono-nf-3.4.0.tar.xz )
  terminus? ( ${COMMON_URI}/Terminus.tar.xz -> Terminus-nf-3.4.0.tar.xz )
  tinos? ( ${COMMON_URI}/Tinos.tar.xz -> Tinos-nf-3.4.0.tar.xz )
  ubuntu? ( ${COMMON_URI}/Ubuntu.tar.xz -> Ubuntu-nf-3.4.0.tar.xz )
  ubuntumono? ( ${COMMON_URI}/UbuntuMono.tar.xz -> UbuntuMono-nf-3.4.0.tar.xz )
  ubuntusans? ( ${COMMON_URI}/UbuntuSans.tar.xz -> UbuntuSans-nf-3.4.0.tar.xz )
  victormono? ( ${COMMON_URI}/VictorMono.tar.xz -> VictorMono-nf-3.4.0.tar.xz )
  zedmono? ( ${COMMON_URI}/ZedMono.tar.xz -> ZedMono-nf-3.4.0.tar.xz )
"

S="${WORKDIR}"
LICENSE="MIT
  OFL-1.1
  Apache-2.0
  CC-BY-SA-4.0
  BitstreamVera
  BSD
  WTFPL-2
  Vic-Fieger-License
  UbuntuFontLicense-1.0"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="media-libs/fontconfig"

CHECKREQS_DISK_BUILD="3G"
CHECKREQS_DISK_USR="4G"

# Enable every font by default; users can opt out via USE=-<font>
IUSE_FLAGS=(${FONTS[*],,})
IUSE=" +nerdfontssymbolsonly $(printf ' +%s' ${IUSE_FLAGS[@]})"
REQUIRED_USE="|| ( nerdfontssymbolsonly ${IUSE_FLAGS[*]} )"

FONT_S=${S}

pkg_pretend() {
  check-reqs_pkg_setup
}

src_install() {
  declare -A font_filetypes
  local otf_file_number ttf_file_number

  otf_file_number=$(ls "${S}" | grep -i '\.otf$' | wc -l)
  ttf_file_number=$(ls "${S}" | grep -i '\.ttf$' | wc -l)

  if [[ ${otf_file_number} != 0 ]]; then
    font_filetypes[otf]=
  fi

  if [[ ${ttf_file_number} != 0 ]]; then
    font_filetypes[ttf]=
  fi

  FONT_SUFFIX="${!font_filetypes[@]}"

  font_src_install
}

pkg_postinst() {
  einfo "Installing font-patcher via an ebuild is difficult due to hardcoded paths."
  einfo "If you need it, clone the upstream repo and run it from there:"
  einfo "https://github.com/ryanoasis/nerd-fonts"

  elog "You may need to enable 50-user.conf via:"
  elog "  eselect fontconfig"
}

