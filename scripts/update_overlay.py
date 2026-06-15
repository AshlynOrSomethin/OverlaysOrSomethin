#!/usr/bin/env python3
"""Auto-update selected overlay ebuilds and Manifests."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

GITHUB_API = "https://api.github.com/repos/{repo}/releases/latest"


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


UNMANAGED_PACKAGES: dict[str, str] = {
    "app-misc/fetchcord": "Upstream release assets do not currently provide a stable Linux binary artifact to package as -bin.",
    "app-editors/sublime-merge": "Can be automated, but currently kept manual because upstream build channel/URL policy can vary.",
    "games-action/lunarclient": "Upstream Linux AppImage naming/channel changes frequently; requires package-specific guardrails.",
    "www-client/thorium-bin": "Upstream release/tag/asset conventions are inconsistent and may require custom mapping.",
    "media-fonts/nerd-fonts": "Very large multi-dist Manifest and ebuild-specific versioning logic require dedicated updater flow.",
}


CONFIGS: tuple[PackageConfig, ...] = (
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
        repo="Floorp-Projects/Floorp",
        asset_pattern=r"^floorp-(?P<version>[0-9.]+)\.deb$",
        distfile_name=lambda v: f"floorp-bin-{v}_amd64.deb",
    ),
    PackageConfig(
        package_name="zen-bin",
        category="www-client",
        directory="www-client/zen-bin",
        repo="zen-browser/desktop",
        asset_pattern=r"^zen-x86_64\.AppImage$",
        version_from_tag=True,
        tag_strip_prefix="",
        distfile_name=lambda v: f"zen-bin-{v}.AppImage",
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
        f"SHA512 {sha512_file(distfile_path)}\\n"
        f"EBUILD {ebuild_name} {ebuild_size} "
        f"BLAKE2B {blake2b_file(ebuild_path)} "
        f"SHA512 {sha512_file(ebuild_path)}\\n"
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

    release = github_request(GITHUB_API.format(repo=cfg.repo))
    asset = find_asset(release, cfg.asset_pattern)
    if asset is None:
        raise RuntimeError(f"No matching asset found for {cfg.package_name}")

    new_ver = version_from_release(cfg, release, asset)
    new_ebuild_name = f"{cfg.package_name}-{new_ver}.ebuild"
    new_ebuild = package_dir / new_ebuild_name

    changed = False
    if new_ver != cur_ver:
        changed = True
        print(f"[{cfg.package_name}] version {cur_ver} -> {new_ver}")
        if not dry_run:
            shutil.copy2(cur_ebuild, new_ebuild)
            cur_ebuild.unlink()
    else:
        print(f"[{cfg.package_name}] already at {cur_ver}; refreshing Manifest")

    if dry_run:
        return changed

    # Always refresh Manifest to keep hashes valid if ebuild changed by hand.
    with tempfile.TemporaryDirectory() as td:
        distfile = Path(td) / asset["name"]
        urllib.request.urlretrieve(asset["browser_download_url"], distfile)  # noqa: S310

        dist_renamed = Path(td) / cfg.distfile_name(new_ver)
        distfile.rename(dist_renamed)

        target_ebuild = new_ebuild if new_ebuild.exists() else cur_ebuild
        write_manifest(
            package_dir,
            cfg.distfile_name(new_ver),
            dist_renamed,
            target_ebuild.name,
            target_ebuild,
        )

    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description="Update overlay ebuilds and Manifests")
    parser.add_argument("--dry-run", action="store_true", help="Show actions only")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    os.chdir(root)

    any_changed = False
    for cfg in CONFIGS:
        changed = update_package(root, cfg, args.dry_run)
        any_changed = any_changed or changed

    print("\nUnmanaged package paths:")
    for path, reason in UNMANAGED_PACKAGES.items():
        print(f"- {path}: {reason}")

    if args.dry_run:
        print("Dry-run complete")
    elif any_changed:
        print("Updates applied")
    else:
        print("No version bumps; manifests refreshed")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
