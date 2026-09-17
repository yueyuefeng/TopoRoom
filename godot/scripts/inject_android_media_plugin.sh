#!/usr/bin/env bash
# Copy TopoRoomMedia Java into the Godot Gradle project and register v2 plugin
# meta-data. .gdap/AAR is the documented path; this keeps the class in the APK
# even when the editor export preset does not load android/plugins.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/godot/android-plugin/toporoom-media/src/main/java/com/toporoom/plugin/TopoRoomMediaPlugin.java"
DEST_DIR="$ROOT/godot/android/build/src/com/toporoom/plugin"
MANIFEST="$ROOT/godot/android/build/AndroidManifest.xml"

if [[ ! -f "$SRC" ]]; then
  echo "Missing plugin Java: $SRC" >&2
  exit 1
fi
if [[ ! -d "$ROOT/godot/android/build" ]]; then
  echo "Godot Android build template not installed (godot/android/build)." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/TopoRoomMediaPlugin.java"

if [[ -f "$MANIFEST" ]] && ! grep -q 'org.godotengine.plugin.v2.TopoRoomMedia' "$MANIFEST"; then
  python3 - "$MANIFEST" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
meta = '''
        <meta-data
            android:name="org.godotengine.plugin.v2.TopoRoomMedia"
            android:value="com.toporoom.plugin.TopoRoomMediaPlugin" />
'''
needle = "</application>"
if needle not in text:
    raise SystemExit("AndroidManifest.xml missing </application>")
path.write_text(text.replace(needle, meta + "    " + needle, 1))
print("Registered TopoRoomMedia v2 meta-data in", path)
PY
fi
echo "Injected TopoRoomMediaPlugin into $DEST_DIR"
