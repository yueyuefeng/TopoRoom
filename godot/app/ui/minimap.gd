extends Control
## S5 top-left minimap: dark frosted square, walls, camera FOV cone.

var yaw := 0.55
var walls_json := ""


func _ready() -> void:
	custom_minimum_size = Vector2(112, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_yaw(v: float) -> void:
	yaw = v
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Tokens.PAGE_DARK_SOFT, true, -1, true)
	draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)
	var parsed: Variant = JSON.parse_string(Session.sceneir_json() if walls_json.is_empty() else walls_json)
	if typeof(parsed) != TYPE_DICTIONARY:
		_draw_fov(r.get_center())
		return
	var storeys: Array = parsed.get("storeys", [])
	if storeys.is_empty() or typeof(storeys[0]) != TYPE_DICTIONARY:
		_draw_fov(r.get_center())
		return
	var walls: Array = storeys[0].get("walls", [])
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
	var pad := 12.0
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
	_draw_fov(r.get_center())


func _draw_fov(c: Vector2) -> void:
	var heading := -yaw + PI
	var spread := 0.55
	var reach := minf(size.x, size.y) * 0.38
	var a := c + Vector2(cos(heading - spread), sin(heading - spread)) * reach
	var b := c + Vector2(cos(heading + spread), sin(heading + spread)) * reach
	draw_colored_polygon(PackedVector2Array([c, a, b]), Color(1, 1, 1, 0.22))
	draw_line(c, a, Color(1, 1, 1, 0.55), 1.0)
	draw_line(c, b, Color(1, 1, 1, 0.55), 1.0)
	draw_circle(c, 4.0, Color.WHITE)
