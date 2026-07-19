#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Orilo"
BUNDLE_ID="com.orilo.app"
EXECUTABLE_NAME="Orilo"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ORILO_DIST_DIR:-$ROOT_DIR/dist}"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$EXECUTABLE_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
SWIFT_BUILD_FLAGS=()

if [[ "${ORILO_DISABLE_SWIFTPM_SANDBOX:-0}" == "1" ]]; then
  SWIFT_BUILD_FLAGS+=(--disable-sandbox)
fi

pkill -x "$EXECUTABLE_NAME" >/dev/null 2>&1 || true
if [ ${#SWIFT_BUILD_FLAGS[@]} -gt 0 ]; then
  swift build "${SWIFT_BUILD_FLAGS[@]}"
  BUILD_BINARY="$(swift build "${SWIFT_BUILD_FLAGS[@]}" --show-bin-path)/$EXECUTABLE_NAME"
else
  swift build
  BUILD_BINARY="$(swift build --show-bin-path)/$EXECUTABLE_NAME"
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/Config/Info.plist" "$INFO_PLIST"
cp "$ROOT_DIR/Config/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
cp "$ROOT_DIR/Config/MenuBarIconTemplate.png" "$APP_RESOURCES/MenuBarIconTemplate.png"
find "$APP_BUNDLE" -exec xattr -c {} \; 2>/dev/null || true

SIGN_IDENTITY="${ORILO_SIGN_IDENTITY:-}"
AD_HOC_SIGN="${ORILO_AD_HOC_SIGN:-0}"

if [[ -n "$SIGN_IDENTITY" ]]; then
  # Stable identity (e.g. an Apple Development cert) keeps the code signature
  # constant across rebuilds, so granted permissions like Accessibility persist.
  codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
elif [[ "$AD_HOC_SIGN" == "1" ]]; then
  codesign --force --sign - "$APP_BUNDLE"
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$EXECUTABLE_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$EXECUTABLE_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
