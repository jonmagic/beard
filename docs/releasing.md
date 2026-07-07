# Releasing Beard

Beard uses `VERSION` as the release version source of truth.

## Local release artifact

Build and sign the macOS arm64 download:

```sh
scripts/package-release
scripts/package-notarized-pkg
```

This writes:

```text
dist/Beard-<version>-macos-arm64.zip
dist/Beard-<version>-macos-arm64.zip.sha256
dist/Beard-<version>-macos-arm64.pkg
dist/Beard-<version>-macos-arm64.pkg.sha256
```

The zip package script signs the `beard` binary with the local Developer ID Application identity, verifies the signature, and includes `README.md`, `LICENSE`, `CHANGELOG.md`, and `docs/user-guide.md` in the archive.

The notarized package script signs the `beard` binary, builds a signed installer package with the local Developer ID Installer identity, submits the package with `xcrun notarytool`, staples the accepted ticket, validates the stapled package, and writes a checksum.

Prerequisites:

1. `Developer ID Application: Jonathan Hoyt (J3536DQT74)`
2. `Developer ID Installer: Jonathan Hoyt (J3536DQT74)`
3. A stored notarytool profile named `tsrs`

Override only when needed:

```sh
BEARD_SIGN_IDENTITY="Developer ID Application: ..." \
BEARD_INSTALLER_IDENTITY="Developer ID Installer: ..." \
BEARD_NOTARYTOOL_PROFILE=other-profile \
scripts/package-notarized-pkg
```

## Future jonmagic.com release

The intended public release path should mirror Tri-State Relay Service:

1. Copy the versioned pkg and/or zip into `~/code/jonmagic/jonmagic.com/src/downloads/`.
2. Add a Beard release data file similar to `src/_data/tsrsRelease.js` that reads this repository's `CHANGELOG.md`.
3. Add a `/beard/` page with a current-release section sourced from the changelog and a download button pointing at `/downloads/Beard-<version>-macos-arm64.pkg`.
4. Add Plausible download tracking similar to the TSRS page.
5. Run the jonmagic.com build before publishing.

Do not rely on an unversioned download URL unless jonmagic explicitly asks for it.
