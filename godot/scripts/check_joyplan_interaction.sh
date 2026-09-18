#!/usr/bin/env bash
# Guard JoyPlan flow: floating islands, new scene graph, Session still owns SceneIR.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
has() { grep -q -- "$2" "$1" || fail "$1 missing $2"; }
lacks() { grep -q -- "$2" "$1" && fail "$1 must not contain $2" || true; }

# Boot path
has "$root/godot/project.godot" 'run/main_scene="res://app/main.tscn"'
has "$root/godot/app/main.gd" "res://app/joyplan_flow/home.tscn"
lacks "$root/godot/app/main.gd" "photo_stub"
lacks "$root/godot/app/main.gd" "引导量房"
lacks "$root/godot/app/main.gd" "_place_fab"
lacks "$root/godot/app/main.gd" "attach_hud"

# Island chrome language
has "$root/godot/app/joyplan_flow/islands.gd" "class_name FlowIslands"
has "$root/godot/app/joyplan_flow/islands.gd" "shadow_size"
has "$root/godot/app/joyplan_flow/islands.gd" "view_toggle"
has "$root/godot/app/joyplan_flow/islands.gd" "bottom_2d_dock"
has "$root/godot/app/joyplan_flow/islands.gd" "green_back_2d"
has "$root/godot/app/joyplan_flow/islands.gd" "right_circles"
has "$root/godot/app/joyplan_flow/islands.gd" "PAGE_GREEN"
lacks "$root/godot/app/joyplan_flow/islands.gd" "JoyplanChrome"
lacks "$root/godot/app/joyplan_flow/islands.gd" "NavBar"

# FSM
has "$root/godot/app/joyplan_flow/router.gd" "SCALE"
has "$root/godot/app/joyplan_flow/router.gd" "EDIT_2D"
has "$root/godot/app/joyplan_flow/router.gd" "EDIT_3D"
has "$root/godot/app/joyplan_flow/router.gd" "ELEVATION"

# S1
has "$root/godot/app/joyplan_flow/home.gd" "拍户型"
has "$root/godot/app/joyplan_flow/home.gd" "相册"
has "$root/godot/app/joyplan_flow/home.gd" "capture_photo"
has "$root/godot/app/joyplan_flow/home.gd" "pick_gallery"

# S2
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" "比例设置"
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" "调整户型"
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" "退出"
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" "确定"
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" '"900"'
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" "LOUPE_ZOOM"
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" "_draw_loupe_cross"
has "$root/godot/app/joyplan_flow/scale_calibrate.gd" "import_photo_vision"

# S3 / S4
has "$root/godot/app/joyplan_flow/edit_2d.gd" "view_toggle"
has "$root/godot/app/joyplan_flow/edit_2d.gd" "bottom_2d_dock"
has "$root/godot/app/joyplan_flow/edit_2d.gd" "ctx_pill"
has "$root/godot/app/joyplan_flow/edit_2d.gd" "翻转"
has "$root/godot/app/joyplan_flow/edit_2d.gd" "复制"
has "$root/godot/app/joyplan_flow/edit_2d.gd" "删除"
has "$root/godot/app/joyplan_flow/library_sheet.gd" "收藏"
has "$root/godot/app/joyplan_flow/library_sheet.gd" "门"
has "$root/godot/app/joyplan_flow/library_sheet.gd" "窗"
has "$root/godot/app/joyplan_flow/library_sheet.gd" "梁管"
has "$root/godot/app/joyplan_flow/library_sheet.gd" "电气"
has "$root/godot/app/joyplan_flow/library_sheet.gd" "长按控件拖到平面图"
has "$root/godot/app/plan_canvas.gd" "_draw_drag_dim"
has "$root/godot/app/plan_canvas.gd" "_format_area_m2"
has "$root/godot/app/plan_canvas.gd" "m²"
has "$root/godot/app/plan_canvas.gd" "joyplan_look"

# S5–S7
has "$root/godot/app/joyplan_flow/edit_3d.gd" "right_circles"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "green_back_2d"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "undo_redo_pill"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "Session.move_shared_vertex"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "Session.update_opening_geom"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "_place_opening_at"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "_tween_extrude"
has "$root/godot/app/joyplan_flow/minimap.gd" "FOV"
has "$root/godot/app/joyplan_flow/ruler_sheet.gd" "Ruler display"
has "$root/godot/app/joyplan_flow/ruler_sheet.gd" "Dimensions"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "PAGE_DIM"

# S8
has "$root/godot/app/joyplan_flow/elevation_index.gd" "Elevation Index"

# No old chrome on the run path
lacks "$root/godot/app/joyplan_flow/edit_3d.gd" "attach_hud"
lacks "$root/godot/app/joyplan_flow/edit_2d.gd" "_place_fab"
lacks "$root/godot/app/joyplan_flow/home.gd" "Studio.nav_bar"

# Session still owns vision / demolition
has "$root/godot/app/session.gd" "import_photo_fake"
has "$root/godot/app/session.gd" "import_photo_vision"
has "$root/godot/app/session.gd" "store_imported_image"
has "$root/godot/app/session.gd" "demolish_wall"
has "$root/godot/app/session.gd" "func flip_opening"
has "$root/godot/app/media_picker.gd" "TopoRoomMedia"
has "$root/godot/export_presets.cfg" "permissions/camera=true"
has "$root/godot/export_presets.cfg" "VIBRATE"
has "$root/godot/export_presets.cfg" "app/_legacy/"

# Tokens
has "$root/godot/app/theme/tokens.gd" "3478F6"
has "$root/godot/app/theme/tokens.gd" "PAGE_ISLAND"
has "$root/godot/app/theme/tokens.gd" "PAGE_GREEN"
lacks "$root/godot/app/theme/tokens.gd" "C45C26"

echo "OK: JoyPlan flow scene graph / island chrome invariants"
