#!/usr/bin/env bash
# Export a Debug APK with Godot 4.3+ (requires export templates + Android SDK).
#
#   GODOT=/path/to/godot ./godot/scripts/export_android_debug.sh [out.apk]
#
# Optional env:
#   ANDROID_HOME / ANDROID_SDK_ROOT  SDK root (platforms;android-34, NDK, build-tools)
#   JAVA_HOME                        OpenJDK 17
#   GODOT_ANDROID_KEYSTORE_DEBUG_PATH / USER / PASSWORD
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT_BIN="${GODOT:-${GODOT_BIN:-godot}}"
OUT="${1:-$ROOT/build/toporoom-android-debug.apk}"
TPL_DIR="${GODOT_TEMPLATES_DIR:-$HOME/.local/share/godot/export_templates/4.3.stable}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1 && [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot 4.3+ binary not found (set GODOT=)." >&2
  exit 1
fi

if [[ ! -f "$TPL_DIR/android_debug.apk" || ! -f "$TPL_DIR/android_source.zip" ]]; then
  echo "Godot 4.3 export templates missing under $TPL_DIR" >&2
  echo "Install Godot_v4.3-stable_export_templates.tpz (android_debug.apk + android_source.zip)." >&2
  exit 1
fi

SO_ARM="$ROOT/godot/bin/libtoporoom.android.template_debug.arm64.so"
if [[ ! -f "$SO_ARM" ]]; then
  echo "Missing $SO_ARM — build first:" >&2
  echo "  ANDROID_NDK=... ./godot/scripts/build_extension.sh android arm64-v8a" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

INSTALL_TPL=(--install-android-build-template)

export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-${ANDROID_HOME:-$HOME/android-sdk}/debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:-android}"

# Editor import once so .glb / .tscn are cached.
"$GODOT_BIN" --headless --path "$ROOT/godot" --import --quit || true
"$GODOT_BIN" --headless --path "$ROOT/godot" "${INSTALL_TPL[@]}" --export-debug "Android" "$OUT"
if [[ ! -s "$OUT" ]]; then
  echo "Export finished but $OUT is missing or empty." >&2
  exit 1
fi
echo "Wrote $OUT"
ls -lh "$OUT"
