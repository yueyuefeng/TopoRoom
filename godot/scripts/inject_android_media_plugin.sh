#!/usr/bin/env bash
# Copy TopoRoomMedia Java into the Godot Gradle project and register v2 plugin
# meta-data, gallery <queries>, and READ_MEDIA_* so OEM package visibility
# works even when the .aar merge is skipped.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/godot/android-plugin/toporoom-media/src/main/java/com/toporoom/plugin/TopoRoomMediaPlugin.java"
DEST_DIR="$ROOT/godot/android/build/src/com/toporoom/plugin"
MANIFEST="$ROOT/godot/android/build/AndroidManifest.xml"
DEBUG_MANIFEST="$ROOT/godot/android/build/src/debug/AndroidManifest.xml"

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

python3 - "$MANIFEST" "$DEBUG_MANIFEST" <<'PY'
import pathlib, sys

QUERIES = '''
    <queries>
        <intent>
            <action android:name="android.intent.action.GET_CONTENT" />
            <data android:mimeType="image/*" />
        </intent>
        <intent>
            <action android:name="android.intent.action.PICK" />
            <data android:mimeType="image/*" />
        </intent>
        <intent>
            <action android:name="android.intent.action.OPEN_DOCUMENT" />
            <data android:mimeType="image/*" />
        </intent>
        <intent>
            <action android:name="android.provider.action.PICK_IMAGES" />
        </intent>
        <intent>
            <action android:name="android.media.action.IMAGE_CAPTURE" />
        </intent>
    </queries>
'''

META = '''
        <meta-data
            android:name="org.godotengine.plugin.v2.TopoRoomMedia"
            android:value="com.toporoom.plugin.TopoRoomMediaPlugin" />
'''

PERMS = [
    ('android.permission.READ_MEDIA_IMAGES',
     '    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />\n'),
    ('android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
     '    <uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />\n'),
]


def patch(path: pathlib.Path) -> None:
    if not path.is_file():
        return
    text = path.read_text()
    if 'org.godotengine.plugin.v2.TopoRoomMedia' not in text and '</application>' in text:
        text = text.replace('</application>', META + '    </application>', 1)
        print('Registered TopoRoomMedia v2 meta-data in', path)
    for needle, snippet in PERMS:
        if needle not in text:
            if '<application' in text:
                text = text.replace('<application', snippet + '    <application', 1)
            elif '<manifest' in text:
                nl = text.find('\n', text.find('<manifest'))
                text = text[:nl + 1] + snippet + text[nl + 1:]
            print('Declared', needle, 'in', path)
    if 'android.intent.action.GET_CONTENT' not in text:
        if '<application' in text:
            text = text.replace('<application', QUERIES + '\n    <application', 1)
        else:
            text = text.replace('</manifest>', QUERIES + '\n</manifest>', 1)
        print('Injected gallery <queries> into', path)
    elif 'android.media.action.IMAGE_CAPTURE' not in text and '<queries>' in text:
        text = text.replace(
            '</queries>',
            '        <intent>\n'
            '            <action android:name="android.media.action.IMAGE_CAPTURE" />\n'
            '        </intent>\n    </queries>',
            1,
        )
        print('Injected IMAGE_CAPTURE <queries> into', path)
    path.write_text(text)


for raw in sys.argv[1:]:
    patch(pathlib.Path(raw))
PY

echo "Injected TopoRoomMediaPlugin into $DEST_DIR"
