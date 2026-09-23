# JoyPlan click path (user screenshots)

Recreated screens. One tap advances. **自由绘制** opens the draw canvas; **导入户型图** is the photo path. AR扫描 / 手绘草图 still toast 即将支持.

| Ours | Reference | Screen |
|------|-----------|--------|
| [01_home.png](./01_home.png) | [ref_01_home.jpg](./ref_01_home.jpg) | Home: 我的项目 / AI厨房 / AI设计 / 拍照速记Pro |
| [02_projects.png](./02_projects.png) | [ref_02_projects.jpg](./ref_02_projects.jpg) | 工程项目 + 新建项目 |
| [03_new_plan.png](./03_new_plan.png) | [ref_03_new_plan.jpg](./ref_03_new_plan.jpg) | 新建户型 list |
| [04_pick_source.png](./04_pick_source.png) | | 选择户型图: 相册 / 拍照 / 使用示例户型 |
| [05_scale_1of2.png](./05_scale_1of2.png) | | 1/2 临摹图比例 + mm keypad (gallery-sim JPEG 723×712) |
| [06_generate_2of2.png](./06_generate_2of2.png) | | 2/2 生成空间 |
| [07_edit_2d.png](./07_edit_2d.png) | | S3 2D editor (image + walls) |
| [08_edit_2d_plus_menu.png](./08_edit_2d_plus_menu.png) | [ref_05_2d_plus_menu.jpg](./ref_05_2d_plus_menu.jpg) | 2D + menu 导入户型图 |

Click path: Home → **我的项目** → **新建项目** → **导入户型图** → 相册选择 / 拍照上传 / 使用示例户型 → **下一步** → **确定** → 2D.

`capture_click_path.gd` copies the sample plan to a cache JPEG (same shape as the Android plugin) then stores it so 1/2 shows that image, not a blank/demo fill.

## Android APIs (0.1.5)

**相册选择** (`TopoRoomMediaPlugin.pick_gallery`):

1. CN OEM (Huawei / Honor / Xiaomi / OPPO / vivo / …): skip Photo Picker first
2. `Intent.ACTION_GET_CONTENT` `image/*` + `CATEGORY_OPENABLE`
3. `ACTION_GET_CONTENT` without `OPENABLE`
4. `ACTION_PICK` `MediaStore.Images.Media.EXTERNAL_CONTENT_URI` (needs `READ_MEDIA_IMAGES` / legacy storage)
5. `ACTION_OPEN_DOCUMENT`
6. `MediaStore.ACTION_PICK_IMAGES` last on CN (first on Pixel / API 33+)

Quick-cancel &lt;450ms retries the next Intent. `content://` → `ContentResolver` + `BitmapFactory` JPEG in `getCacheDir()/imports`. Android 11 `<queries>` for GET_CONTENT / PICK / OPEN_DOCUMENT / PICK_IMAGES. Photo Picker / GET_CONTENT / OPEN_DOCUMENT do not need storage permission.

**拍照上传** (`capture_photo`): `CAMERA` runtime + `MediaStore.ACTION_IMAGE_CAPTURE` with Godot `FileProvider` `com.toporoom.godot.fileprovider` `EXTRA_OUTPUT` under `getExternalFilesDir(DIRECTORY_PICTURES)/imports`, `createNewFile()`, `ClipData` URI grants. Launches even when `queryIntentActivities` is empty. `onMainResume` recovers OEM `RESULT_CANCELED` after a written file. Then same scale → 2D path.

**OEM caveats:** Photo Picker often opens-and-cancels on CN skins; do not put it first. API 31+ package visibility hides camera/gallery without `<queries>`. Xiaomi/Huawei HEIC albums are recompressed to JPEG. Some camera apps write `EXTRA_OUTPUT` then return canceled.

## Debug APK 0.1.8 (`versionCode` 9)

Same debug cert as 0.1.0–0.1.7. Install over the previous build.

0.1.8 moves the 2D/3D four-icon view-mode pill to a bottom compass. 自由绘制 header stays at the top.

| | |
|---|---|
| Package | `com.toporoom.godot` **0.1.8** (`versionCode` 9) arm64-v8a Debug |
| File | `toporoom-android-debug.apk` (74 MB) |
| SHA-256 | `0f93f37ad665fecdb547c638c35695c7a50624566413f9ed121d426ef166dc44` |
| Cert SHA-256 | `d265124cfe5c728db2c9de55303750dcde10adb76d6c66c6b37763721a7492f3` |
| Direct | https://litter.catbox.moe/oraxhg.apk |
| Mirror | https://gofile.io/d/Ax6iAJGg |
