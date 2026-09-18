#!/usr/bin/env bash
# Scripted check: roam/edit never call add_wall/set_measurement except via Session;
# lighting package includes DirectionalLight3D with shadows.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
has() { grep -q -- "$2" "$1"; }
lacks() { grep -q -- "$2" "$1" && fail "$1 must not contain $2" || true; }

lacks "$root/godot/app/_legacy/roam.gd" "host.add_wall"
lacks "$root/godot/app/_legacy/roam.gd" "host.set_measurement"
lacks "$root/godot/app/_legacy/roam.gd" "add_wall"
lacks "$root/godot/app/joyplan_flow/edit_3d.gd" "host.add_wall"
lacks "$root/godot/app/joyplan_flow/edit_3d.gd" "host.set_measurement"
lacks "$root/godot/app/lighting.gd" "add_wall"
lacks "$root/godot/app/lighting.gd" "set_measurement"

has "$root/godot/app/session.gd" "host.add_wall" || fail "session.gd missing host.add_wall"
has "$root/godot/app/session.gd" "host.set_measurement" || fail "session.gd missing host.set_measurement"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "Session.move_shared_vertex" || fail "edit_3d missing Session.move_shared_vertex"
has "$root/godot/app/joyplan_flow/edit_3d.gd" "Session.update_opening_geom" || fail "edit_3d missing Session.update_opening_geom"
has "$root/godot/app/lighting.gd" "DirectionalLight3D" || fail "lighting missing DirectionalLight3D"
has "$root/godot/app/lighting.gd" "shadow_enabled" || fail "lighting missing shadow_enabled"
has "$root/godot/app/joyplan_flow/edit_2d.gd" "_go_3d" || fail "edit_2d missing 3D entry"

echo "OK: 3D edit / lighting invariants"
