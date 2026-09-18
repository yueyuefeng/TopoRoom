# TopoRoomMedia — Godot Android camera / gallery plugin

Phone **拍户型图** and **从相册导入** must open the system camera and picker,
then return a JPEG/PNG path into Godot. `DisplayServer.file_dialog_show` only
opens a document picker, so this plugin wraps Android Intents.

```
GDScript MediaPicker
    → Engine.get_singleton("TopoRoomMedia")
        → TopoRoomMediaPlugin (GodotPlugin v2)
            → ACTION_IMAGE_CAPTURE  (拍照上传)
            → gallery chain (相册选择)
                → copy content:// into app cache/imports as JPEG
                    → signal image_picked(path)
                        → Session.store_imported_image → user://imports/
                            → 1/2 临摹图比例 → 2/2 生成空间 → 2D
```

## Gallery chain (Chinese OEMs)

`MediaStore.ACTION_PICK_IMAGES` often opens and immediately cancels on Huawei /
Honor / Xiaomi / OPPO / vivo / … so those brands **start with**
`Intent.ACTION_GET_CONTENT` `image/*`. Pixel / AOSP keeps Photo Picker first.

Then, if the picker returns in &lt; 450 ms (stub / no-op):

1. `ACTION_GET_CONTENT` + `CATEGORY_OPENABLE` `image/*`
2. `ACTION_GET_CONTENT` without `OPENABLE` (some OEM galleries)
3. `ACTION_PICK` `MediaStore.Images.Media.EXTERNAL_CONTENT_URI` (needs
   `READ_MEDIA_IMAGES` / legacy `READ_EXTERNAL_STORAGE`)
4. `ACTION_OPEN_DOCUMENT`
5. `ACTION_PICK_IMAGES` last on CN OEMs

`<queries>` in the plugin manifest is required on Android 11+ or
`resolveActivity` / `queryIntentActivities` look empty. GET_CONTENT /
OPEN_DOCUMENT / Photo Picker do **not** need storage permission. `ACTION_PICK`
does; if the user denies, that step is skipped.

The selected `content://` URI is decoded with `ContentResolver` +
`BitmapFactory` and written to `getCacheDir()/imports/*.jpg` so Godot
`FileAccess` can read it. HEIC from OEM albums is recompressed to JPEG.

## What the plugin does

| GDScript | Android |
|----------|---------|
| `capture_photo()` | Request `CAMERA` if needed, then `MediaStore.ACTION_IMAGE_CAPTURE` with `FileProvider` `EXTRA_OUTPUT` |
| `pick_gallery()` | OEM-aware chain above; never only Photo Picker |
| signal `image_picked(path)` | Absolute JPEG path under app cache/imports |
| signal `pick_cancelled` | User backed out after a real picker (slow cancel) |
| signal `pick_error(message)` | No gallery / permission denied / copy failed |

Godot already ships `FileProvider` at `{applicationId}.fileprovider`
(`com.toporoom.godot.fileprovider`) covering `files/` and `external-files/`.
Camera capture writes under `getExternalFilesDir(DIRECTORY_PICTURES)/imports`
(or `getFilesDir()/imports`), `createNewFile()`, then
`MediaStore.ACTION_IMAGE_CAPTURE` with `EXTRA_OUTPUT` + `ClipData` URI grants.
Android 11+ needs `<queries>` for `IMAGE_CAPTURE` or `queryIntentActivities`
is empty — we still launch; ClipData grants the camera app write access.
Some OEM cameras return `RESULT_CANCELED` after writing the file; `onMainResume`
picks that up. The JPEG is copied into `getCacheDir()/imports` for Godot.

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
