# OverlaysOrSomethin

Gentoo overlay with personal ebuilds, focused on binary packages where possible.

## Add the overlay

### Option 1: eselect-repository (recommended)

1. Install support tools:
```bash
sudo emerge --ask app-eselect/eselect-repository dev-vcs/git
```

2. Enable your local overlay metadata source if needed:
```bash
sudo eselect repository enable guru
sudo emerge --sync guru
```

3. Add this overlay:
```bash
sudo eselect repository add OverlaysOrSomethin git https://github.com/AshlynOrSomethin/OverlaysOrSomethin.git
```

4. Sync overlays:
```bash
sudo emaint sync -r OverlaysOrSomethin
```

5. Install packages from the overlay:
```bash
sudo emerge -av www-client/floorp-bin
```

### Option 2: Manual repository.conf entry

1. Create the local repo checkout:
```bash
sudo mkdir -p /var/db/repos/OverlaysOrSomethin
sudo git clone https://github.com/AshlynOrSomethin/OverlaysOrSomethin.git /var/db/repos/OverlaysOrSomethin
```

2. Add config at `/etc/portage/repos.conf/OverlaysOrSomethin.conf`:
```ini
[OverlaysOrSomethin]
location = /var/db/repos/OverlaysOrSomethin
sync-type = git
sync-uri = https://github.com/AshlynOrSomethin/OverlaysOrSomethin.git
auto-sync = yes
priority = 50
```

3. Sync and use:
```bash
sudo emaint sync -r OverlaysOrSomethin
```

## Auto-update workflow

This repo includes:
- `scripts/update_overlay.py`
- `.github/workflows/update-ebuilds.yml`

What it does:
- Checks latest GitHub releases for supported packages.
- Renames ebuilds when version bumps are found.
- Rebuilds package `Manifest` files (DIST and EBUILD hashes).
- Mirrors Gentoo `www-client/firefox` source ebuilds/files daily.
- Commits and pushes changes automatically from GitHub Actions.
- Prints unmanaged package paths that still require manual maintenance.

Currently automated package updates:
- `app-admin/xpipe-bin`
- `net-im/equibop`
- `net-im/vesktop`
- `app-emulation/wine-cachyos` (directory mirror from `NoBodyZ/nbdy_overlay`)
- `www-client/floorp-bin`
- `www-client/zen-bin`
- `www-client/firefox-bin`
- `www-client/firefox-esr-bin`
- `games-action/lunarclient`
- `app-editors/fresh-editor`
- `media-sound/spotatui`
- `www-client/firefox` (source mirror for `:esr` and `:rapid`)

Run manually in CI:
- GitHub Actions: `Auto Update Ebuilds` -> `Run workflow`

Run locally:
```bash
python3 scripts/update_overlay.py
```

Dry-run locally:
```bash
python3 scripts/update_overlay.py --dry-run
```

## Notes

The updater currently auto-version/manifests these packages:
- `app-admin/xpipe-bin`
- `net-im/equibop`
- `net-im/vesktop`
- `app-emulation/wine-cachyos` (directory mirror from `NoBodyZ/nbdy_overlay`)
- `www-client/floorp-bin`
- `www-client/zen-bin`
- `www-client/firefox-bin`
- `www-client/firefox-esr-bin`
- `games-action/lunarclient`
- `app-editors/fresh-editor`
- `media-sound/spotatui`
- `www-client/firefox` (source mirror for `:esr` and `:rapid`)

For local custom Firefox patches, use Portage user patches:
- Place patch files in `/etc/portage/patches/www-client/firefox/`
- Example: `/etc/portage/patches/www-client/firefox/software-volume.patch`
- Overlay Firefox ebuilds first check for `/etc/portage/patches/www-client/firefox/software-volume.patch` and apply it if present.
- If missing, they fall back to the bundled overlay patch `files/firefox-audio-software-volume.patch`.
- `eapply_user` still runs afterward for any additional user patches.

The script also prints a list of unmanaged package paths and why they are not yet auto-updated. Those remain manual until a package-specific updater rule is added.
