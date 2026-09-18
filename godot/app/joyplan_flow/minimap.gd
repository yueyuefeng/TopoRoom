extends Control
## S5 minimap: dark frosted square + white dot + FOV wedge that follows the camera.

var walls_json: String = ""
var yaw := 0.55
var pitch := -0.48
var target := Vector3.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(108, 108)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_TOP_LEFT)
	offset_left = 14
	offset_top = 72
	offset_right = 122
	offset_bottom = 180


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.12, 0.13, 0.16, 0.72), true, -1.0)
	draw_rect(r, Color(1, 1, 1, 0.18), false, 1.2)
	var parsed: Variant = JSON.parse_string(walls_json) if not walls_json.is_empty() else {}
	var walls: Array = []
	if typeof(parsed) == TYPE_DICTIONARY:
		var storeys: Array = parsed.get("storeys", [])
		if not storeys.is_empty() and typeof(storeys[0]) == TYPE_DICTIONARY:
			walls = storeys[0].get("walls", [])
	if walls.is_empty():
		return
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		min_x = min(min_x, min(float(a.get("x", 0)), float(b.get("x", 0))))
		min_y = min(min_y, min(float(a.get("y", 0)), float(b.get("y", 0))))
		max_x = max(max_x, max(float(a.get("x", 0)), float(b.get("x", 0))))
		max_y = max(max_y, max(float(a.get("y", 0)), float(b.get("y", 0))))
	var pad := 10.0
	var dx: float = max(max_x - min_x, 1.0)
	var dy: float = max(max_y - min_y, 1.0)
	var sc: float = min((size.x - 2.0 * pad) / dx, (size.y - 2.0 * pad) / dy)
	var ox := pad + ((size.x - 2.0 * pad) - dx * sc) * 0.5
	var oy := pad + ((size.y - 2.0 * pad) - dy * sc) * 0.5
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		var p0 := Vector2(ox + (float(a.get("x", 0)) - min_x) * sc, size.y - (oy + (float(a.get("y", 0)) - min_y) * sc))
		var p1 := Vector2(ox + (float(b.get("x", 0)) - min_x) * sc, size.y - (oy + (float(b.get("y", 0)) - min_y) * sc))
		draw_line(p0, p1, Color(1, 1, 1, 0.85), 1.6)
	var cx := ox + (target.x * 1000.0 - min_x) * sc
	var cy := size.y - (oy + (target.z * 1000.0 - min_y) * sc)
	var origin := Vector2(cx, cy)
	draw_circle(origin, 4.0, Color.WHITE)
	var dir := Vector2(sin(yaw), -cos(yaw))
	var left := dir.rotated(-0.45) * 28.0
	var right := dir.rotated(0.45) * 28.0
	var poly := PackedVector2Array([origin, origin + left, origin + right])
	draw_colored_polygon(poly, Color(1, 1, 1, 0.28))
	draw_line(origin, origin + left, Color.WHITE, 1.0)
	draw_line(origin, origin + right, Color.WHITE, 1.0)
