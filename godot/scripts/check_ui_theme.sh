#!/usr/bin/env bash
# Guard tokens + camera/gallery plugin + Session command façade.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
has() { grep -q -- "$2" "$1" || fail "$1 missing $2"; }
lacks() { grep -q -- "$2" "$1" && fail "$1 must not contain $2" || true; }

has "$root/godot/app/theme/tokens.gd" "WALL_SHEAR"
has "$root/godot/app/theme/tokens.gd" "WALL_MASONRY"
has "$root/godot/app/theme/tokens.gd" "OPENING_DOOR"
has "$root/godot/app/theme/tokens.gd" "FONT_DISPLAY"
has "$root/godot/app/theme/tokens.gd" "3478F6"
has "$root/godot/app/theme/tokens.gd" "PAGE_ISLAND"
has "$root/godot/app/theme/app_theme.gd" "StyleBoxFlat"
has "$root/godot/app/theme/app_theme.gd" "PrimaryButton"
has "$root/godot/app/theme/app_theme.gd" "SheetPanel"
has "$root/godot/app/theme/studio.gd" "func chip"
has "$root/godot/app/theme/studio.gd" "func action_card"
has "$root/godot/app/session.gd" "请先画至少四面墙"
has "$root/godot/project.godot" "Studio="
has "$root/godot/app/main.gd" "joyplan_flow/home.tscn"
has "$root/godot/app/joyplan_flow/home.gd" "pick_gallery"
has "$root/godot/app/joyplan_flow/home.gd" "示例户型"
has "$root/godot/app/joyplan_flow/home.gd" "相册导入"
has "$root/godot/app/session.gd" "load_gold_sample"
has "$root/godot/app/media_picker.gd" "TopoRoomMedia"
has "$root/godot/app/session.gd" "import_photo_fake"
has "$root/godot/app/session.gd" "import_photo_vision"
has "$root/godot/app/session.gd" "store_imported_image"
has "$root/godot/app/session.gd" "demolish_wall"
has "$root/godot/app/plan_canvas.gd" "Tokens.wall_stroke"
has "$root/godot/app/plan_canvas.gd" "_draw_dim"
has "$root/godot/app/lighting.gd" "wall_material_for_kind"
has "$root/godot/export_presets.cfg" "plugins/TopoRoomMedia=true"
has "$root/godot/export_presets.cfg" "permissions/camera=true"
has "$root/godot/scripts/inject_android_media_plugin.sh" "TopoRoomMediaPlugin"
has "$root/godot/export_presets.cfg" "READ_MEDIA_IMAGES"
has "$root/godot/android/plugins/TopoRoomMedia.gdap" "TopoRoomMedia"
has "$root/godot/android-plugin/toporoom-media/src/main/java/com/toporoom/plugin/TopoRoomMediaPlugin.java" "BitmapFactory"
has "$root/godot/export_presets.cfg" 'keystore/debug="android/keystore/debug.keystore"'
has "$root/godot/scripts/bump_android_version.sh" "versionCode"
has "$root/godot/scripts/wire_android_signing.sh" "debug.keystore"
has "$root/godot/android/version.json" "versionName"
test -f "$root/godot/android/keystore/debug.keystore" || fail "missing committed debug.keystore"
test -f "$root/godot/android/keystore/debug.cert.sha256" || fail "missing debug.cert.sha256"

lacks "$root/godot/app/main.gd" "_btn("
lacks "$root/godot/app/plan_canvas.gd" "const WALL :="
lacks "$root/godot/app/joyplan_flow/home.gd" "拍户型"
lacks "$root/godot/app/joyplan_flow/home.gd" '"相册"'
lacks "$root/godot/app/joyplan_flow/home.gd" "选择户型图"
lacks "$root/godot/app/joyplan_flow/edit_2d.gd" "host.add_wall"
lacks "$root/godot/app/theme/tokens.gd" "C45C26"
lacks "$root/godot/app/theme/tokens.gd" "F4EEE4"

echo "OK: Godot UI theme / camera+gallery invariants"
