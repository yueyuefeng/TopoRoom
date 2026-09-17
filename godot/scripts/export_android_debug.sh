#!/usr/bin/env bash
# Export a Debug APK with Godot 4.3+ (requires export templates + Android SDK).
#
#   GODOT=/path/to/godot ./godot/scripts/export_android_debug.sh
#
# This is NOT run in the Linux CMake CI. Cloud VMs usually lack Godot export
# templates; run locally after building arm64 (and optional x86_64) .so files.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT_BIN="${GODOT:-${GODOT_BIN:-godot}}"
OUT="${1:-$ROOT/build/toporoom-android-debug.apk}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot 4.3+ binary not found (set GODOT=)." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
if [[ -x "$ROOT/godot/scripts/build_android_plugin.sh" ]]; then
  "$ROOT/godot/scripts/build_android_plugin.sh" || echo "WARN: TopoRoomMedia plugin AAR not rebuilt; using android/plugins if present."
fi
# Editor import once so .glb / .tscn are cached.
"$GODOT_BIN" --headless --path "$ROOT/godot" --import --quit || true
"$GODOT_BIN" --headless --path "$ROOT/godot" --export-debug "Android" "$OUT"
echo "Wrote $OUT"
