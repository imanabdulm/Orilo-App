#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Orilo"
BUNDLE_ID="com.orilo.app"
EXECUTABLE_NAME="Orilo"
VERSION="0.1.0"
SIGN_IDENTITY="-"
CONFIGURATION="release"
NOTARY_PROFILE=""

usage() {
  cat <<USAGE
usage: $0 [--identity "Developer ID Application: ..."] [--notary-profile NAME] [--debug]

Builds a local distributable Orilo.app archive (ZIP + DMG).

Options:
  --identity        Code signing identity. Defaults to ad-hoc signing (-).
  --notary-profile  notarytool keychain profile name. When set, the app is
                    notarized and stapled after signing. Create one once with:
                      xcrun notarytool store-credentials "NAME" \\
                        --apple-id you@example.com --team-id TEAMID \\
                        --password APP_SPECIFIC_PASSWORD
  --debug           Build with SwiftPM debug configuration instead of release.
  --help            Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --identity)
      SIGN_IDENTITY="${2:?missing signing identity}"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="${2:?missing notary profile name}"
      shift 2
      ;;
    --debug)
      CONFIGURATION="debug"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
WORK_DIR="${TMPDIR:-/tmp}/orilo-release"
STAGE_DIR="$WORK_DIR/stage"
APP_BUNDLE="$STAGE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$EXECUTABLE_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$RELEASE_DIR/${APP_NAME}-${VERSION}.zip"
WORK_ZIP_PATH="$WORK_DIR/${APP_NAME}-${VERSION}.zip"
DMG_PATH="$RELEASE_DIR/${APP_NAME}-${VERSION}.dmg"
WORK_DMG_PATH="$WORK_DIR/${APP_NAME}-${VERSION}.dmg"

BUILD_ARGS=()
if [[ "${ORILO_DISABLE_SWIFTPM_SANDBOX:-0}" == "1" ]]; then
  BUILD_ARGS+=(--disable-sandbox)
fi

if [[ "$CONFIGURATION" == "release" ]]; then
  BUILD_ARGS+=(--configuration release)
fi

echo "Building $APP_NAME ($CONFIGURATION)..."
if [ ${#BUILD_ARGS[@]} -gt 0 ]; then
  swift build "${BUILD_ARGS[@]}"
  BUILD_BINARY="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)/$EXECUTABLE_NAME"
else
  swift build
  BUILD_BINARY="$(swift build --show-bin-path)/$EXECUTABLE_NAME"
fi

echo "Staging app bundle..."
rm -rf "$WORK_DIR"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/Config/Info.plist" "$INFO_PLIST"
cp "$ROOT_DIR/Config/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
cp "$ROOT_DIR/Config/MenuBarIconTemplate.png" "$APP_RESOURCES/MenuBarIconTemplate.png"
find "$APP_BUNDLE" -exec xattr -c {} \; 2>/dev/null || true

echo "Validating bundle metadata..."
plutil -lint "$INFO_PLIST" >/dev/null
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" | grep -qx "$BUNDLE_ID"
/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$INFO_PLIST" | grep -qx "$EXECUTABLE_NAME"

echo "Signing app bundle with identity: $SIGN_IDENTITY"
# Notarization requires the hardened runtime; enable it for real (non-ad-hoc)
# Developer ID identities. Ad-hoc local builds skip it.
SIGN_ARGS=(--force --sign "$SIGN_IDENTITY" --timestamp=none)
if [[ "$SIGN_IDENTITY" != "-" ]]; then
  SIGN_ARGS=(--force --sign "$SIGN_IDENTITY" --timestamp --options runtime)
fi
codesign "${SIGN_ARGS[@]}" "$APP_BUNDLE"
find "$APP_BUNDLE" -name '._*' -delete
find "$APP_BUNDLE" -exec xattr -d com.apple.FinderInfo {} \; 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "Creating zip archive..."
mkdir -p "$RELEASE_DIR"
rm -f "$ZIP_PATH" "$WORK_ZIP_PATH" "$DMG_PATH" "$WORK_DMG_PATH"
(cd "$STAGE_DIR" && COPYFILE_DISABLE=1 zip -qry -X "$WORK_ZIP_PATH" "$APP_NAME.app")

if [[ -n "$NOTARY_PROFILE" ]]; then
  echo "Submitting to Apple notary service (profile: $NOTARY_PROFILE)..."
  xcrun notarytool submit "$WORK_ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  echo "Stapling notarization ticket to the app..."
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  # Re-zip so the distributed archive contains the stapled app.
  rm -f "$WORK_ZIP_PATH"
  (cd "$STAGE_DIR" && COPYFILE_DISABLE=1 zip -qry -X "$WORK_ZIP_PATH" "$APP_NAME.app")
fi

cp "$WORK_ZIP_PATH" "$ZIP_PATH"

echo "Creating DMG image..."
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$APP_BUNDLE" \
  -ov \
  -format UDZO \
  "$WORK_DMG_PATH" >/dev/null
cp "$WORK_DMG_PATH" "$DMG_PATH"

echo "Release artifact:"
echo "  $APP_BUNDLE"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo
echo "Validation commands:"
echo "  codesign -dvvv \"$APP_BUNDLE\""
echo "  codesign --verify --deep --strict --verbose=2 \"$APP_BUNDLE\""
echo
if [[ "$SIGN_IDENTITY" == "-" ]]; then
  echo "Note: this build is ad-hoc signed for local testing. Gatekeeper assessment and notarization require a Developer ID identity."
else
  echo "Developer ID follow-up:"
  echo "  spctl -a -vv \"$APP_BUNDLE\""
fi
