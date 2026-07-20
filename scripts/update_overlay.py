#!/usr/bin/env python3
"""Auto-update selected overlay ebuilds and Manifests."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import urllib.request
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Callable, Optional

GITHUB_API = "https://api.github.com/repos/{repo}/releases/latest"
FLATHUB_APPSTREAM_API = "https://flathub.org/api/v2/appstream/{app_id}"
GENTOO_CONTENTS_API = "https://api.github.com/repos/gentoo/gentoo/contents/{path}"
ARCHLINUX_PACKAGING_PKGBUILD = "https://gitlab.archlinux.org/archlinux/packaging/packages/{package}/-/raw/main/PKGBUILD"
ARCHLINUX_SOURCE_ARCHIVE = "https://sources.archlinux.org/other/{package}/{package}-{pkgver}.tar.xz"
GENTOO_FIREFOX_PATH = "www-client/firefox"
NBDY_OVERLAY_REPO = "https://codeberg.org/NoBodyZ/nbdy_overlay.git"
NBDY_WINE_PATH = "app-emulation/wine-cachyos"
FIREFOX_PATCH_NAME = "firefox-audio-software-volume.patch"
FIREFOX_USER_PATCH_PATH = "/etc/portage/patches/${CATEGORY}/${PN}/software-volume.patch"
FIREFOX_PATCH_BLOCK = f"""\
	if [[ ! -f \"{FIREFOX_USER_PATCH_PATH}\" ]]; then
		if ! nonfatal eapply \"${{FILESDIR}}/{FIREFOX_PATCH_NAME}\"; then
			ewarn \"Bundled software-volume patch no longer applies cleanly.\"
			ewarn \"Place an updated patch at {FIREFOX_USER_PATCH_PATH} to override.\"
		fi
	fi
"""
FIREFOX_PATCH_CONTENT = """--- a/dom/media/AudioStream.cpp
+++ b/dom/media/AudioStream.cpp
@@ -9,6 +9,7 @@
 #include <algorithm>

 #include \"AudioConverter.h\"
+#include \"AudioSampleFormat.h\"
 #include \"CubebUtils.h\"
 #include \"UnderrunHandler.h\"
 #include \"VideoUtils.h\"
@@ -297,11 +298,7 @@
      return;
    }

-  MonitorAutoLock mon(mMonitor);
-  if (InvokeCubeb(cubeb_stream_set_volume,
-                  aVolume * CubebUtils::GetVolumeScale()) != CUBEB_OK) {
-    LOGE(\"Could not change volume on cubeb stream.\");
-  }
+  mSoftwareVolume = static_cast<float>(aVolume * CubebUtils::GetVolumeScale());
 }

 void AudioStream::SetStreamName(const nsAString& aStreamName) {
@@ -663,6 +660,12 @@
                                                mAudioThreadChanged);
    }

+  float volume = mSoftwareVolume;
+  if (volume != 1.0f) {
+    AudioBufferInPlaceScale(static_cast<AudioDataValue*>(aBuffer), volume,
+                            static_cast<uint32_t>(aFrames) * mOutChannels);
+  }
+
    mDumpFile.Write(static_cast<const AudioDataValue*>(aBuffer),
                         aFrames * mOutChannels);

--- a/dom/media/AudioStream.h
+++ b/dom/media/AudioStream.h
@@ -367,6 +367,9 @@
         MOZ_GUARDED_BY(mMonitor);
    std::atomic<bool> mPlaybackComplete;
    // Both written on the MDSM thread, read on the audio thread.
+  // Volume applied in software in DataCallback instead of via
+  // cubeb_stream_set_volume, so the system mixer never sees changes.
+  std::atomic<float> mSoftwareVolume{1.0f};
    std::atomic<float> mPlaybackRate;
    std::atomic<bool> mPreservesPitch;
    // Audio thread only
"""


@dataclass(frozen=True)
class PackageConfig:
    package_name: str
    category: str
    directory: str
    repo: str
    asset_pattern: str
    distfile_name: Callable[[str], str]
    version_from_tag: bool = False
    tag_strip_prefix: str = "v"
    source: str = "github"
    flathub_app_id: Optional[str] = None
    source_asset_name: Optional[Callable[[str], str]] = None
    source_download_url: Optional[Callable[[str], str]] = None


UNMANAGED_PACKAGES: dict[str, str] = {
    "app-misc/fetchcord": "Upstream release assets do not currently provide a stable Linux binary artifact to package as -bin.",
    "app-editors/sublime-merge": "Can be automated, but currently kept manual because upstream build channel/URL policy can vary.",
    "games-action/hytale-launcher-bin": "Not automated yet; upstream packaging/release mapping requires a package-specific updater rule.",
    "games-util/nbtexplorer-bin": "Not automated yet; upstream packaging/release mapping requires a package-specific updater rule.",
    "media-fonts/apple-fonts": "Not automated yet; upstream packaging/release mapping requires a package-specific updater rule.",
    "www-client/thorium-bin": "Upstream release/tag/asset conventions are inconsistent and may require custom mapping.",
    "net-misc/localsend-bin": "Not automated yet; upstream packaging/release mapping requires a package-specific updater rule.",
    "net-misc/mqtt-explorer-bin": "Not automated yet; upstream packaging/release mapping requires a package-specific updater rule.",
    "net-print/brother-hll2305w": "Not automated yet; upstream packaging/release mapping requires a package-specific updater rule.",
    "media-fonts/nerd-fonts": "Very large multi-dist Manifest and ebuild-specific versioning logic require dedicated updater flow.",
}


def version_sort_key(version: str) -> tuple[tuple[int, object], ...]:
    key: list[tuple[int, object]] = []
    for token in re.split(r"([0-9]+)", version):
        if not token:
            continue
        if token.isdigit():
            key.append((1, int(token)))
        else:
            key.append((0, token))
    return tuple(key)


CONFIGS: tuple[PackageConfig, ...] = (
    PackageConfig(
        package_name="xpipe-bin",
        category="app-admin",
        directory="app-admin/xpipe-bin",
        repo="xpipe-io/xpipe",
        asset_pattern=r"^xpipe-installer-linux-x86_64\.deb$",
        version_from_tag=True,
        tag_strip_prefix="",
        distfile_name=lambda v: f"xpipe-bin-{v}-x86_64.deb",
    ),
    PackageConfig(
        package_name="equibop",
        category="net-im",
        directory="net-im/equibop",
        repo="Equicord/Equibop",
        asset_pattern=r"^equibop_(?P<version>[0-9.]+)_amd64\.deb$",
        distfile_name=lambda v: f"equibop-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="vesktop",
        category="net-im",
        directory="net-im/vesktop",
        repo="Vencord/Vesktop",
        asset_pattern=r"^vesktop_(?P<version>[0-9.]+)_amd64\.deb$",
        distfile_name=lambda v: f"vesktop-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="floorp-bin",
        category="www-client",
        directory="www-client/floorp-bin",
        repo="AshlynOrSomethin/AudioStreamPatcher",
        asset_pattern=r"^floorp-patched-(?P<version>[0-9A-Za-z._-]+)-v(?P=version)-amd64\.deb$",
        distfile_name=lambda v: f"floorp-bin-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="zen-bin",
        category="www-client",
        directory="www-client/zen-bin",
        repo="AshlynOrSomethin/AudioStreamPatcher",
        asset_pattern=r"^zen-patched-(?P<version>[0-9A-Za-z._-]+)-x86_64\.AppImage$",
        distfile_name=lambda v: f"zen-bin-{v}.AppImage",
    ),
    PackageConfig(
        package_name="firefox-bin",
        category="www-client",
        directory="www-client/firefox-bin",
        repo="AshlynOrSomethin/AudioStreamPatcher",
        asset_pattern=r"^firefox-patched-(?P<version>[0-9.]+)-amd64\.deb$",
        distfile_name=lambda v: f"firefox-bin-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="firefox-esr-bin",
        category="www-client",
        directory="www-client/firefox-esr-bin",
        repo="AshlynOrSomethin/AudioStreamPatcher",
        asset_pattern=r"^firefox-esr-patched-(?P<version>[0-9.]+esr)-amd64\.deb$",
        distfile_name=lambda v: f"firefox-esr-bin-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="lunarclient",
        category="games-action",
        directory="games-action/lunarclient",
        repo="",
        source="flathub",
        flathub_app_id="com.lunarclient.LunarClient",
        source_asset_name=lambda v: f"Lunar%20Client-{v}-ow.AppImage",
        source_download_url=lambda v: f"https://launcherupdates.lunarclientcdn.com/Lunar%20Client-{v}-ow.AppImage",
        asset_pattern=r"",
        distfile_name=lambda v: f"lunarclient-{v}.AppImage",
    ),
    PackageConfig(
        package_name="fresh-editor",
        category="app-editors",
        directory="app-editors/fresh-editor",
        repo="sinelaw/fresh",
        asset_pattern=r"^fresh-editor_(?P<version>[0-9.]+)-1_amd64\.deb$",
        distfile_name=lambda v: f"fresh-editor-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="spotatui",
        category="media-sound",
        directory="media-sound/spotatui",
        repo="LargeModGames/spotatui",
        asset_pattern=r"^spotatui_(?P<version>[0-9.]+)-1_amd64\.deb$",
        distfile_name=lambda v: f"spotatui-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="mkinitcpio",
        category="sys-kernel",
        directory="sys-kernel/mkinitcpio",
        repo="",
        source="archlinux",
        asset_pattern=r"",
        distfile_name=lambda v: f"mkinitcpio-{v.split('.', 1)[0]}.tar.xz",
    ),
)


def sha512_file(path: Path) -> str:
    h = hashlib.sha512()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def blake2b_file(path: Path) -> str:
    h = hashlib.blake2b(digest_size=64)
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def github_request(url: str) -> dict:
    token = os.getenv("GITHUB_TOKEN")
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "overlay-auto-updater",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"

    req = urllib.request.Request(
        url,
        headers=headers,
    )
    with urllib.request.urlopen(req, timeout=60) as resp:  # noqa: S310
        return json.loads(resp.read().decode("utf-8"))


def http_get_bytes(url: str, timeout: int = 60) -> bytes:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "overlay-auto-updater", "Accept": "*/*"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:  # noqa: S310
        return resp.read()


def http_get_text(url: str, timeout: int = 60) -> str:
    return http_get_bytes(url, timeout=timeout).decode("utf-8")


def parse_pkgbuild_scalar(pkgbuild_text: str, var_name: str) -> str:
    prefix = f"{var_name}="
    for line in pkgbuild_text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if not line.startswith(prefix):
            continue

        value = line[len(prefix) :].strip()
        if value.startswith(("\"", "'")) and value.endswith(("\"", "'")) and len(value) >= 2:
            value = value[1:-1]
        return value

    raise RuntimeError(f"Unable to parse '{var_name}' from PKGBUILD")


def gentoo_contents(path: str) -> list[dict]:
    data = github_request(GENTOO_CONTENTS_API.format(path=path))
    if not isinstance(data, list):
        raise RuntimeError(f"Unexpected GitHub contents response for {path}")
    return data


def sync_gentoo_directory(src_path: str, dest_dir: Path) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    for entry in gentoo_contents(src_path):
        entry_type = entry.get("type")
        name = entry.get("name")
        if not isinstance(name, str):
            continue
        if entry_type == "file":
            download_url = entry.get("download_url")
            if not isinstance(download_url, str) or not download_url:
                raise RuntimeError(f"Missing download_url for {src_path}/{name}")
            (dest_dir / name).write_bytes(http_get_bytes(download_url, timeout=300))
        elif entry_type == "dir":
            sync_gentoo_directory(f"{src_path}/{name}", dest_dir / name)


def detect_firefox_slot(ebuild_text: str) -> str:
    m = re.search(r"(?m)^MOZ_ESR=(.*)$", ebuild_text)
    if not m:
        raise RuntimeError("Unable to detect MOZ_ESR from firefox ebuild")
    return "esr" if m.group(1).strip() else "rapid"


def inject_firefox_patch_logic(ebuild_text: str) -> str:
    match = re.search(r"(?m)^([ \t]*)eapply_user$", ebuild_text)
    if not match:
        raise RuntimeError("Unable to find eapply_user in firefox ebuild")
    indent = match.group(1)

    injected_block = FIREFOX_PATCH_BLOCK.replace("\t", indent).rstrip("\n")
    legacy_block = (
        f'{indent}if [[ -f "{FIREFOX_USER_PATCH_PATH}" ]]; then\n'
        f'{indent}\teapply "{FIREFOX_USER_PATCH_PATH}"\n'
        f"{indent}else\n"
        f'{indent}\tif ! nonfatal eapply "${{FILESDIR}}/{FIREFOX_PATCH_NAME}"; then\n'
        f'{indent}\t\tewarn "Bundled software-volume patch no longer applies cleanly."\n'
        f'{indent}\t\tewarn "Place an updated patch at {FIREFOX_USER_PATCH_PATH} to override."\n'
        f"{indent}\tfi\n"
        f"{indent}fi"
    )

    # Remove previously injected block variants so the new block can be inserted once.
    for existing in (legacy_block, injected_block):
        ebuild_text = ebuild_text.replace(f"{existing}\n\n{indent}eapply_user", f"{indent}eapply_user")

    replacement = f"{injected_block}\n\n{indent}eapply_user"
    return re.sub(r"(?m)^([ \t]*)eapply_user$", replacement, ebuild_text, count=1)


def manifest_line(kind: str, name: str, path: Path) -> str:
    size = path.stat().st_size
    return (
        f"{kind} {name} {size} "
        f"BLAKE2B {blake2b_file(path)} "
        f"SHA512 {sha512_file(path)}\n"
    )


def upsert_manifest_line(lines: list[str], kind: str, name: str, new_line: str) -> bool:
    prefix = f"{kind} {name} "
    for i, line in enumerate(lines):
        if line.startswith(prefix):
            lines[i] = new_line
            return True
    lines.append(new_line)
    return False


def rewrite_firefox_manifest(
    package_dir: Path,
    ebuild_names: set[str],
) -> None:
    manifest_path = package_dir / "Manifest"
    lines = manifest_path.read_text(encoding="utf-8").splitlines(keepends=True)

    for ebuild_name in sorted(ebuild_names):
        upsert_manifest_line(
            lines,
            "EBUILD",
            ebuild_name,
            manifest_line("EBUILD", ebuild_name, package_dir / ebuild_name),
        )

    files_dir = package_dir / "files"
    for aux_path in sorted(files_dir.rglob("*")):
        if not aux_path.is_file():
            continue
        aux_rel = aux_path.relative_to(files_dir).as_posix()
        upsert_manifest_line(
            lines,
            "AUX",
            aux_rel,
            manifest_line("AUX", aux_rel, aux_path),
        )

    manifest_path.write_text("".join(lines), encoding="utf-8")


def rewrite_package_manifest(package_dir: Path) -> None:
    manifest_path = package_dir / "Manifest"
    lines = manifest_path.read_text(encoding="utf-8").splitlines(keepends=True)

    # Keep DIST/AUX entries from mirrored source, but always ensure local file digests exist.
    for ebuild_path in sorted(package_dir.glob("*.ebuild")):
        upsert_manifest_line(
            lines,
            "EBUILD",
            ebuild_path.name,
            manifest_line("EBUILD", ebuild_path.name, ebuild_path),
        )

    metadata_path = package_dir / "metadata.xml"
    if metadata_path.is_file():
        upsert_manifest_line(
            lines,
            "MISC",
            "metadata.xml",
            manifest_line("MISC", "metadata.xml", metadata_path),
        )

    manifest_path.write_text("".join(lines), encoding="utf-8")


def directories_equal(left: Path, right: Path) -> bool:
    left_files = {
        p.relative_to(left).as_posix(): p
        for p in left.rglob("*")
        if p.is_file()
    }
    right_files = {
        p.relative_to(right).as_posix(): p
        for p in right.rglob("*")
        if p.is_file()
    }
    if set(left_files) != set(right_files):
        return False

    for rel_path, left_file in left_files.items():
        if left_file.read_bytes() != right_files[rel_path].read_bytes():
            return False
    return True


def update_wine_cachyos_mirror(root: Path, dry_run: bool) -> bool:
    package_dir = root / NBDY_WINE_PATH
    now = datetime.now(UTC).strftime("%Y-%m-%d")

    with tempfile.TemporaryDirectory() as td:
        mirror_repo = Path(td) / "nbdy_overlay"
        subprocess.run(
            ["git", "clone", "--depth", "1", NBDY_OVERLAY_REPO, str(mirror_repo)],
            check=True,
            capture_output=True,
            text=True,
        )

        source_dir = mirror_repo / NBDY_WINE_PATH
        if not source_dir.is_dir():
            raise RuntimeError(f"Missing mirrored path in source repository: {NBDY_WINE_PATH}")

        staged_dir = Path(td) / "wine-cachyos"
        shutil.copytree(source_dir, staged_dir)
        rewrite_package_manifest(staged_dir)

        source_commit = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=mirror_repo,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

        if package_dir.exists() and directories_equal(package_dir, staged_dir):
            print(f"[wine-cachyos] no mirror changes ({now})")
            return False

        if dry_run:
            print(f"[wine-cachyos] would update mirror ({now}) source={source_commit}")
            return True

        if package_dir.exists():
            shutil.rmtree(package_dir)
        shutil.copytree(staged_dir, package_dir)

        print(f"[wine-cachyos] mirrored nbdy_overlay source={source_commit}")
        return True


def update_firefox_source_mirror(root: Path, dry_run: bool) -> bool:
    package_dir = root / GENTOO_FIREFOX_PATH
    now = datetime.now(UTC).strftime("%Y-%m-%d")

    with tempfile.TemporaryDirectory() as td:
        tmp_package = Path(td) / "firefox"
        tmp_package.mkdir(parents=True, exist_ok=True)

        root_entries = gentoo_contents(GENTOO_FIREFOX_PATH)

        ebuild_entries: list[dict] = []
        for entry in root_entries:
            name = entry.get("name")
            if not isinstance(name, str):
                continue
            if entry.get("type") == "file" and name.endswith(".ebuild"):
                ebuild_entries.append(entry)
            elif entry.get("type") == "file":
                download_url = entry.get("download_url")
                if not isinstance(download_url, str) or not download_url:
                    raise RuntimeError(f"Missing download_url for {GENTOO_FIREFOX_PATH}/{name}")
                (tmp_package / name).write_bytes(http_get_bytes(download_url, timeout=300))
            elif entry.get("type") == "dir" and name == "files":
                sync_gentoo_directory(f"{GENTOO_FIREFOX_PATH}/files", tmp_package / "files")

        if not ebuild_entries:
            raise RuntimeError("No firefox ebuilds found in Gentoo tree")

        all_ebuild_names: set[str] = set()
        latest_by_slot: dict[str, tuple[str, str]] = {}
        for entry in ebuild_entries:
            name = entry["name"]
            all_ebuild_names.add(name)
            download_url = entry.get("download_url")
            if not isinstance(download_url, str) or not download_url:
                raise RuntimeError(f"Missing download_url for {GENTOO_FIREFOX_PATH}/{name}")
            ebuild_text = http_get_text(download_url, timeout=300)

            m = re.match(r"^firefox-(.+)\.ebuild$", name)
            if not m:
                continue
            version = m.group(1)
            slot = detect_firefox_slot(ebuild_text)
            current = latest_by_slot.get(slot)
            if current is None or version_sort_key(version) > version_sort_key(current[0]):
                latest_by_slot[slot] = (version, name)

            (tmp_package / name).write_text(ebuild_text, encoding="utf-8")

        for required_slot in ("esr", "rapid"):
            if required_slot not in latest_by_slot:
                raise RuntimeError(f"Unable to find firefox {required_slot} ebuild upstream")

        for slot in ("esr", "rapid"):
            ebuild_name = latest_by_slot[slot][1]
            ebuild_path = tmp_package / ebuild_name
            injected = inject_firefox_patch_logic(ebuild_path.read_text(encoding="utf-8"))
            ebuild_path.write_text(injected, encoding="utf-8")

        files_dir = tmp_package / "files"
        files_dir.mkdir(exist_ok=True)
        (files_dir / FIREFOX_PATCH_NAME).write_text(FIREFOX_PATCH_CONTENT, encoding="utf-8")

        rewrite_firefox_manifest(tmp_package, all_ebuild_names)

        if package_dir.exists() and directories_equal(package_dir, tmp_package):
            print(f"[firefox] no mirror changes ({now})")
            return False

        if dry_run:
            print(
                f"[firefox] would update mirror ({now}) "
                f"esr={latest_by_slot['esr'][1]} rapid={latest_by_slot['rapid'][1]}"
            )
            return True

        if package_dir.exists():
            shutil.rmtree(package_dir)
        shutil.copytree(tmp_package, package_dir)
        print(
            f"[firefox] mirrored Gentoo source ebuilds "
            f"esr={latest_by_slot['esr'][1]} rapid={latest_by_slot['rapid'][1]}"
        )
        return True


def flathub_appstream_request(app_id: str) -> dict:
    req = urllib.request.Request(
        FLATHUB_APPSTREAM_API.format(app_id=app_id),
        headers={"User-Agent": "overlay-auto-updater"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:  # noqa: S310
        return json.loads(resp.read().decode("utf-8"))


def download_distfile(url: str, destination: Path) -> None:
    headers = {
        "User-Agent": "overlay-auto-updater",
        "Accept": "application/octet-stream,*/*;q=0.8",
    }
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=300) as resp, destination.open("wb") as out:  # noqa: S310
        shutil.copyfileobj(resp, out)


def find_asset(release: dict, pattern: str) -> Optional[dict]:
    rx = re.compile(pattern)
    for asset in release.get("assets", []):
        if rx.match(asset.get("name", "")):
            return asset
    return None


def current_version(package_dir: Path, package_name: str) -> tuple[str, Path]:
    rx = re.compile(rf"^{re.escape(package_name)}-(.+)\.ebuild$")
    matches: list[tuple[str, Path]] = []
    for entry in package_dir.glob("*.ebuild"):
        m = rx.match(entry.name)
        if m:
            matches.append((m.group(1), entry))
    if len(matches) != 1:
        raise RuntimeError(
            f"Expected exactly one ebuild in {package_dir}, found {len(matches)}"
        )
    return matches[0]


def write_manifest(
    package_dir: Path,
    distfile_name: str,
    distfile_path: Path,
    ebuild_name: str,
    ebuild_path: Path,
) -> None:
    dist_size = distfile_path.stat().st_size
    ebuild_size = ebuild_path.stat().st_size
    manifest = (
        f"DIST {distfile_name} {dist_size} "
        f"BLAKE2B {blake2b_file(distfile_path)} "
        f"SHA512 {sha512_file(distfile_path)}\n"
        f"EBUILD {ebuild_name} {ebuild_size} "
        f"BLAKE2B {blake2b_file(ebuild_path)} "
        f"SHA512 {sha512_file(ebuild_path)}\n"
    )
    (package_dir / "Manifest").write_text(manifest, encoding="utf-8")


def version_from_release(cfg: PackageConfig, release: dict, asset: dict) -> str:
    if cfg.version_from_tag:
        tag = release.get("tag_name", "")
        if cfg.tag_strip_prefix and tag.startswith(cfg.tag_strip_prefix):
            tag = tag[len(cfg.tag_strip_prefix) :]
        if not tag:
            raise RuntimeError(f"Unable to parse version from tag for {cfg.package_name}")
        return tag

    rx = re.compile(cfg.asset_pattern)
    m = rx.match(asset["name"])
    if not m or "version" not in m.groupdict():
        raise RuntimeError(f"Asset pattern missing version capture for {cfg.package_name}")
    return m.group("version")


def update_package(root: Path, cfg: PackageConfig, dry_run: bool) -> bool:
    package_dir = root / cfg.directory
    cur_ver, cur_ebuild = current_version(package_dir, cfg.package_name)

    if cfg.source == "github":
        release = github_request(GITHUB_API.format(repo=cfg.repo))
        asset = find_asset(release, cfg.asset_pattern)
        if asset is None:
            raise RuntimeError(f"No matching asset found for {cfg.package_name}")
        new_ver = version_from_release(cfg, release, asset)
        source_name = asset["name"]
        source_url = asset["browser_download_url"]
    elif cfg.source == "flathub":
        if not cfg.flathub_app_id:
            raise RuntimeError(f"Missing flathub_app_id for {cfg.package_name}")
        appstream = flathub_appstream_request(cfg.flathub_app_id)
        releases = appstream.get("releases", [])
        if not releases:
            raise RuntimeError(f"No releases found for {cfg.package_name}")

        newest = max(releases, key=lambda r: int(r.get("timestamp", 0)))
        new_ver = newest.get("version", "")
        if not new_ver:
            raise RuntimeError(f"Unable to parse Flathub version for {cfg.package_name}")
        if cfg.source_asset_name is None or cfg.source_download_url is None:
            raise RuntimeError(f"Missing source mapping for {cfg.package_name}")
        source_name = cfg.source_asset_name(new_ver)
        source_url = cfg.source_download_url(new_ver)
    elif cfg.source == "archlinux":
        pkgbuild_url = ARCHLINUX_PACKAGING_PKGBUILD.format(package=cfg.package_name)
        pkgbuild_text = http_get_text(pkgbuild_url)
        pkgver = parse_pkgbuild_scalar(pkgbuild_text, "pkgver")
        pkgrel = parse_pkgbuild_scalar(pkgbuild_text, "pkgrel")

        new_ver = f"{pkgver}.{pkgrel}"
        source_name = f"{cfg.package_name}-{pkgver}.tar.xz"
        source_url = ARCHLINUX_SOURCE_ARCHIVE.format(
            package=cfg.package_name,
            pkgver=pkgver,
        )
    else:
        raise RuntimeError(f"Unsupported source '{cfg.source}' for {cfg.package_name}")

    new_ebuild_name = f"{cfg.package_name}-{new_ver}.ebuild"
    new_ebuild = package_dir / new_ebuild_name

    changed = False
    if new_ver != cur_ver:
        changed = True
        print(f"[{cfg.package_name}] version {cur_ver} -> {new_ver}")
    else:
        print(f"[{cfg.package_name}] already at {cur_ver}; refreshing Manifest")

    if dry_run:
        return changed

    # Always refresh Manifest to keep hashes valid if ebuild changed by hand.
    with tempfile.TemporaryDirectory() as td:
        distfile = Path(td) / source_name
        download_distfile(source_url, distfile)

        dist_renamed = Path(td) / cfg.distfile_name(new_ver)
        distfile.rename(dist_renamed)

        if changed:
            shutil.copy2(cur_ebuild, new_ebuild)

        target_ebuild = new_ebuild if new_ebuild.exists() else cur_ebuild
        write_manifest(
            package_dir,
            cfg.distfile_name(new_ver),
            dist_renamed,
            target_ebuild.name,
            target_ebuild,
        )

    if changed:
        cur_ebuild.unlink()

    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description="Update overlay ebuilds and Manifests")
    parser.add_argument("--dry-run", action="store_true", help="Show actions only")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    os.chdir(root)

    any_changed = False
    failures: list[tuple[str, str]] = []
    for cfg in CONFIGS:
        try:
            changed = update_package(root, cfg, args.dry_run)
            any_changed = any_changed or changed
        except Exception as exc:
            failures.append((cfg.package_name, str(exc)))
            print(f"[{cfg.package_name}] ERROR: {exc}")

    try:
        firefox_changed = update_firefox_source_mirror(root, args.dry_run)
        any_changed = any_changed or firefox_changed
    except Exception as exc:
        failures.append(("firefox", str(exc)))
        print(f"[firefox] ERROR: {exc}")

    try:
        wine_changed = update_wine_cachyos_mirror(root, args.dry_run)
        any_changed = any_changed or wine_changed
    except Exception as exc:
        failures.append(("wine-cachyos", str(exc)))
        print(f"[wine-cachyos] ERROR: {exc}")

    print("\nUnmanaged package paths:")
    for path, reason in UNMANAGED_PACKAGES.items():
        print(f"- {path}: {reason}")

    if failures:
        print("\nPackage update failures:")
        for package_name, error in failures:
            print(f"- {package_name}: {error}")

    if args.dry_run:
        if failures:
            print("Dry-run complete with errors")
        else:
            print("Dry-run complete")
    elif any_changed:
        if failures:
            print("Updates applied with errors")
        else:
            print("Updates applied")
    else:
        if failures:
            print("No version bumps; manifests refreshed for successful packages only")
        else:
            print("No version bumps; manifests refreshed")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
