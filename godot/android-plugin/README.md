# TopoRoomMedia — Godot Android camera / gallery plugin

Phone **拍户型图** and **从相册导入** must open the system camera and picker,
then return a JPEG/PNG path into Godot. `DisplayServer.file_dialog_show` only
opens a document picker, so this plugin wraps Android Intents.

```
GDScript MediaPicker
    → Engine.get_singleton("TopoRoomMedia")
        → TopoRoomMediaPlugin (GodotPlugin v2)
            → ACTION_IMAGE_CAPTURE  (拍户型图)
            → ACTION_PICK_IMAGES / ACTION_GET_CONTENT  (从相册导入)
                → copy bytes into app files / Pictures/imports
                    → signal image_picked(path)
                        → Session.store_imported_image → user://imports/
                            → FakeVisionAdapter → SceneIR walls
```

## What the plugin does

| GDScript | Android |
|----------|---------|
| `capture_photo()` | Request `CAMERA` if needed, then `MediaStore.ACTION_IMAGE_CAPTURE` with `FileProvider` `EXTRA_OUTPUT` |
| `pick_gallery()` | API 33+: `ACTION_PICK_IMAGES`. Older: `ACTION_GET_CONTENT` `image/*`, then `ACTION_PICK` |
| signal `image_picked(path)` | Absolute path to a JPEG in the app's files |
| signal `pick_cancelled` | User backed out |
| signal `pick_error(message)` | No camera app / permission denied / copy failed |

Godot already ships `FileProvider` at `{applicationId}.fileprovider`
(`com.toporoom.godot.fileprovider`). The capture file lives under the app's
external pictures / `imports` folder so that provider can share it with the
camera app.

## Permissions

Declared in:

- Plugin `AndroidManifest.xml` (merged at Gradle export)
- `godot/export_presets.cfg`: `permissions/camera`, `read_external_storage`,
  `write_external_storage`, custom `READ_MEDIA_IMAGES`

Runtime: GDScript `OS.request_permission("android.permission.CAMERA")` and the
plugin also requests it before launching the camera. Photo Picker /
`GET_CONTENT` does not need storage permission.

## Desktop / editor fallback

If the singleton is missing (Linux editor, CI screenshots), `MediaPicker`
opens a `FileDialog` with `*.png,*.jpg,*.jpeg,*.webp`. Same preview → FakeVision
path.

## Build the AAR

Needs the Godot Android gradle template once (so `godot-lib.template_debug.aar`
exists) plus Android SDK:

```bash
./godot/scripts/build_android_plugin.sh
# → godot/android/plugins/TopoRoomMedia.debug.aar
# → godot/android/plugins/TopoRoomMedia.release.aar
```

`TopoRoomMedia.gdap` names the plugin `TopoRoomMedia` so Godot 4.3 registers
the v2 meta-data `org.godotengine.plugin.v2.TopoRoomMedia`. Enable it in
`export_presets.cfg` (`plugins/TopoRoomMedia=true`). The export script also
copies the Java into `android/build/src` so the class is always in the APK.

Debug APK export (`./godot/scripts/export_android_debug.sh`) rebuilds the AAR
first.

## Source layout

```
godot/android-plugin/toporoom-media/   Java library
godot/android/plugins/*.gdap + *.aar   picked up by Godot Gradle export
godot/app/media_picker.gd              GDScript façade
godot/app/photo_stub.gd                preview + FakeVision + 拆改
```
