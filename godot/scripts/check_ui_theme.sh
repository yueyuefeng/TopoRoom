#!/usr/bin/env bash
# Guard the design-system UI: tokens, chips (not a raw Button stack), 拍户型图 stub.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
has() { grep -q -- "$2" "$1" || fail "$1 missing $2"; }
lacks() { grep -q -- "$2" "$1" && fail "$1 must not contain $2" || true; }

has "$root/godot/app/theme/tokens.gd" "WALL_SHEAR"
has "$root/godot/app/theme/tokens.gd" "WALL_MASONRY"
has "$root/godot/app/theme/tokens.gd" "OPENING_DOOR"
has "$root/godot/app/theme/tokens.gd" "FONT_DISPLAY"
has "$root/godot/app/theme/app_theme.gd" "StyleBoxFlat"
has "$root/godot/app/theme/app_theme.gd" "PrimaryButton"
has "$root/godot/app/theme/studio.gd" "func chip"
has "$root/godot/app/session.gd" "请先画至少四面墙"
has "$root/godot/app/theme/studio.gd" "HudGlass"
has "$root/godot/project.godot" "Studio="
has "$root/godot/app/main.gd" "拍户型图"
has "$root/godot/app/main.gd" "新建方案"
has "$root/godot/app/main.gd" "引导量房"
has "$root/godot/app/main.gd" "示例一室"
has "$root/godot/app/main.gd" "Snackbar"
has "$root/godot/app/photo_stub.gd" "使用示例户型图"
has "$root/godot/app/photo_stub.gd" "确认承重"
has "$root/godot/app/photo_stub.gd" "整段拆除"
has "$root/godot/app/session.gd" "import_photo_fake"
has "$root/godot/app/session.gd" "demolish_wall"
has "$root/godot/app/plan_canvas.gd" "Tokens.wall_stroke"
has "$root/godot/app/plan_canvas.gd" "_draw_dim"
has "$root/godot/app/edit_3d.gd" "attach_hud"
has "$root/godot/app/edit_3d.gd" "白天"
has "$root/godot/app/roam.gd" "attach_hud"
has "$root/godot/app/lighting.gd" "wall_material_for_kind"

# Home must not be a vertical stack of default Buttons as the only CTA.
lacks "$root/godot/app/main.gd" "_btn("
lacks "$root/godot/app/plan_canvas.gd" "const WALL :="
lacks "$root/godot/app/photo_stub.gd" "host.add_wall"

echo "OK: Godot UI theme / JoyPlan layout invariants"
