#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Orilo"
EXECUTABLE_NAME="Orilo"
INSTALL_DIR="${ORILO_INSTALL_DIR:-/Applications}"
DIST_DIR="${ORILO_DIST_DIR:-/private/tmp/orilo-install}"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"
OLD_TARGET_APPS=("$INSTALL_DIR/Lunavo.app")
RUN_AFTER_INSTALL=0

usage() {
  cat <<USAGE
usage: $0 [--run]

Builds Orilo, installs it to /Applications, and replaces older local copies.

Options:
  --run   Open Orilo after installing.
  --help  Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run)
      RUN_AFTER_INSTALL=1
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

# Default to a stable Apple Development identity so the code signature stays
# constant across rebuilds — that keeps granted permissions (Accessibility)
# from being reset every install. Falls back to ad-hoc only if no identity is
# found, which is the case that breaks Accessibility persistence.
if [[ -z "${ORILO_SIGN_IDENTITY:-}" ]]; then
  ORILO_SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | grep -oE '"Apple Development: [^"]+"' | head -1 | tr -d '"')"
fi

echo "Building local Orilo.app..."
SIGN_IDENTITY="${ORILO_SIGN_IDENTITY:-}"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "  Signing with: $SIGN_IDENTITY"
fi
ORILO_DIST_DIR="$DIST_DIR" \
ORILO_DISABLE_SWIFTPM_SANDBOX="${ORILO_DISABLE_SWIFTPM_SANDBOX:-1}" \
ORILO_SIGN_IDENTITY="$SIGN_IDENTITY" \
ORILO_AD_HOC_SIGN="${ORILO_AD_HOC_SIGN:-1}" \
"$ROOT_DIR/script/build_and_run.sh" --verify

echo "Stopping running Orilo..."
pkill -x "$EXECUTABLE_NAME" >/dev/null 2>&1 || true

echo "Installing to $TARGET_APP..."
mkdir -p "$INSTALL_DIR"
rm -rf "$TARGET_APP"
for old_app in "${OLD_TARGET_APPS[@]}"; do
  if [[ "$old_app" != "$TARGET_APP" && -e "$old_app" ]]; then
    rm -rf "$old_app"
  fi
done
cp -R "$APP_BUNDLE" "$TARGET_APP"
find "$TARGET_APP" -exec xattr -c {} \; 2>/dev/null || true
touch "$TARGET_APP"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -f "$TARGET_APP" >/dev/null 2>&1 || true
fi

# Refresh macOS icon caches so the new AppIcon shows in notifications, Dock,
# and Finder. NotificationCenter alone is not enough — usernoted is the daemon
# that caches/renders notification icons, and iconservicesagent caches the rest.
killall NotificationCenter >/dev/null 2>&1 || true
killall usernoted >/dev/null 2>&1 || true
killall iconservicesagent >/dev/null 2>&1 || true

echo "Installed:"
echo "  $TARGET_APP"

if [[ "$RUN_AFTER_INSTALL" == "1" ]]; then
  echo "Opening Orilo..."
  /usr/bin/open -n "$TARGET_APP"
fi
