#!/usr/bin/env bash
# Export a Debug APK with Godot 4.3+ (requires export templates + Android SDK).
#
#   GODOT=/path/to/godot ./godot/scripts/export_android_debug.sh
#
# Standing rule: every APK bumps versionCode/versionName and reuses the
# committed debug keystore (每次构建升版本；签名固定).
# Set SKIP_VERSION_BUMP=1 only to rebuild the same version (not the default).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT_BIN="${GODOT:-${GODOT_BIN:-godot}}"
OUT="${1:-$ROOT/build/toporoom-android-debug.apk}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot 4.3+ binary not found (set GODOT=)." >&2
  exit 1
fi

"$ROOT/godot/scripts/wire_android_signing.sh"
if [[ "${SKIP_VERSION_BUMP:-}" != "1" ]]; then
  "$ROOT/godot/scripts/bump_android_version.sh"
else
  echo "SKIP_VERSION_BUMP=1 — keeping $(python3 -c "import json; print(json.load(open('$ROOT/godot/android/version.json'))['versionName'])")"
fi

mkdir -p "$(dirname "$OUT")"
if [[ -x "$ROOT/godot/scripts/build_android_plugin.sh" ]]; then
  "$ROOT/godot/scripts/build_android_plugin.sh" || echo "WARN: TopoRoomMedia plugin AAR not rebuilt; using android/plugins if present."
fi
if [[ -x "$ROOT/godot/scripts/inject_android_media_plugin.sh" ]]; then
  "$ROOT/godot/scripts/inject_android_media_plugin.sh"
fi
# Editor import once so .glb / .tscn are cached.
"$GODOT_BIN" --headless --path "$ROOT/godot" --import --quit || true
"$GODOT_BIN" --headless --path "$ROOT/godot" --export-debug "Android" "$OUT"
echo "Wrote $OUT"
