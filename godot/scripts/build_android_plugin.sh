#!/usr/bin/env bash
# Build the TopoRoomMedia Godot Android plugin (camera + gallery Intents) into
# godot/android/plugins/*.aar so Gradle export can merge it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$ROOT/godot/android-plugin"
OUT="$ROOT/godot/android/plugins"
GODOT_LIB="${GODOT_LIB_AAR:-}"

if [[ -z "$GODOT_LIB" ]]; then
  for c in \
    "$ROOT/godot/android/build/libs/debug/godot-lib.template_debug.aar" \
    "$ROOT/godot/android/build/libs/release/godot-lib.template_release.aar"
  do
    if [[ -f "$c" ]]; then
      GODOT_LIB="$c"
      break
    fi
  done
fi
if [[ -z "$GODOT_LIB" || ! -f "$GODOT_LIB" ]]; then
  echo "godot-lib AAR not found. Export the Android gradle project once, or set GODOT_LIB_AAR." >&2
  exit 1
fi
export GODOT_LIB_AAR="$GODOT_LIB"

if [[ ! -x "$PLUGIN/gradlew" ]]; then
  if [[ -x "$ROOT/godot/android/build/gradlew" ]]; then
    cp "$ROOT/godot/android/build/gradlew" "$PLUGIN/gradlew"
    rm -rf "$PLUGIN/gradle"
    cp -a "$ROOT/godot/android/build/gradle" "$PLUGIN/gradle"
  else
    echo "No Gradle wrapper. Install Godot Android build template first." >&2
    exit 1
  fi
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$SDK" ]]; then
  echo "ANDROID_HOME is not set." >&2
  exit 1
fi
printf 'sdk.dir=%s\n' "$SDK" > "$PLUGIN/local.properties"

"$PLUGIN/gradlew" -p "$PLUGIN" :toporoom-media:assembleDebug :toporoom-media:assembleRelease --quiet
mkdir -p "$OUT"
DEBUG_AAR="$(find "$PLUGIN/toporoom-media/build/outputs/aar" -name '*debug*.aar' | head -n 1)"
RELEASE_AAR="$(find "$PLUGIN/toporoom-media/build/outputs/aar" -name '*release*.aar' | head -n 1)"
if [[ -z "$DEBUG_AAR" || -z "$RELEASE_AAR" ]]; then
  echo "Plugin AAR missing after gradle assemble." >&2
  ls -R "$PLUGIN/toporoom-media/build/outputs" >&2 || true
  exit 1
fi
cp "$DEBUG_AAR" "$OUT/TopoRoomMedia.debug.aar"
cp "$RELEASE_AAR" "$OUT/TopoRoomMedia.release.aar"
echo "Wrote $OUT/TopoRoomMedia.debug.aar and TopoRoomMedia.release.aar"
