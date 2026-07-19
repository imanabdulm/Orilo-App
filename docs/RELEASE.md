# Orilo Release Notes

## Local Release Build

Build local release archives:

```bash
./script/release.sh
```

The script creates:

- a temporary staged app at `$TMPDIR/orilo-release/stage/Orilo.app`
- a zip archive at `release/Orilo-0.1.0.zip`
- a compressed DMG at `release/Orilo-0.1.0.dmg`

The default build is ad-hoc signed with `codesign --sign -`. This is suitable
for local testing, moving the app into `/Applications`, and validating the app
bundle structure. It is also useful for private beta testing, but macOS may
still show a Gatekeeper warning because the app is not Developer ID signed and
not notarized.

If the host environment blocks SwiftPM's internal sandbox, run:

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
ORILO_DISABLE_SWIFTPM_SANDBOX=1 \
./script/release.sh
```

For a faster local beta smoke test, build the same archives from a debug binary:

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" \
ORILO_DISABLE_SWIFTPM_SANDBOX=1 \
./script/release.sh --debug
```

## Developer ID Build

For a distributable build, pass a Developer ID Application identity:

```bash
./script/release.sh --identity "Developer ID Application: Your Name (TEAMID)"
```

After that, validate with:

```bash
codesign --verify --deep --strict --verbose=2 "$TMPDIR/orilo-release/stage/Orilo.app"
spctl -a -vv "$TMPDIR/orilo-release/stage/Orilo.app"
hdiutil imageinfo "release/Orilo-0.1.0.dmg"
```

Notarization still requires Apple developer credentials and is not performed by
the local script.

## Why Staging Uses `$TMPDIR`

The app is staged outside the project folder because some file-provider-backed
locations can attach Finder metadata to `.app` bundles. Strict code signing
rejects that metadata. The final zip and DMG are copied back into `release/`.
