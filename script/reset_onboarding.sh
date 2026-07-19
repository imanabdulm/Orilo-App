#!/usr/bin/env bash
set -euo pipefail

SUPPORT_DIR="$HOME/Library/Application Support"
PREFERENCE_FILES=(
  "$SUPPORT_DIR/Orilo/AppPreferences.json"
)

pkill -x "Orilo" >/dev/null 2>&1 || true

for preferences_file in "${PREFERENCE_FILES[@]}"; do
  if [[ -f "$preferences_file" ]]; then
    /usr/bin/ruby -rjson -e '
      path = ARGV.fetch(0)
      data = JSON.parse(File.read(path))
      data["hasCompletedOnboarding"] = false
      File.write(path, JSON.pretty_generate(data) + "\n")
    ' "$preferences_file"
    echo "Reset onboarding in: $preferences_file"
  fi
done

echo "Onboarding will show the next time Orilo starts."
