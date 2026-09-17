extends Control
## 户型图 canvas driven by SceneIR JSON (walls / 门窗洞 / 垭口). Not a mesh editor.

var snapshot: Dictionary = {}

const WALL := Color(0.13, 0.13, 0.13)
const DOOR := Color(0.18, 0.49, 0.22)
const WINDOW := Color(0.08, 0.40, 0.75)
const ARCH := Color(0.42, 0.11, 0.60)
const LABEL := Color(0.26, 0.26, 0.26)
const EMPTY := Color(0.46, 0.46, 0.46)
const BG := Color(0.97, 0.95, 0.92)
const GRID := Color(0.13, 0.13, 0.13, 0.08)


func set_sceneir_json(text: String) -> void:
	snapshot = {}
	if not text.is_empty():
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			snapshot = parsed
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var storeys: Array = snapshot.get("storeys", [])
	var walls: Array = []
	var rooms: Array = []
	var storey_height := 0.0
	if not storeys.is_empty() and typeof(storeys[0]) == TYPE_DICTIONARY:
		var s: Dictionary = storeys[0]
		walls = s.get("walls", [])
		rooms = s.get("rooms", [])
		storey_height = float(s.get("heightMm", 0))
	if walls.is_empty():
		draw_string(_font(), Vector2(16, size.y * 0.5), "户型图（尚无墙）", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, EMPTY)
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
	var pad := 48.0
	var dx: float = max(max_x - min_x, 1.0)
	var dy: float = max(max_y - min_y, 1.0)
	var scale: float = min((size.x - 2.0 * pad) / dx, (size.y - 2.0 * pad) / dy)
	var ox: float = pad + ((size.x - 2.0 * pad) - dx * scale) * 0.5
	var oy: float = pad + ((size.y - 2.0 * pad) - dy * scale) * 0.5

	var g := 0.0
	while g < size.x:
		draw_line(Vector2(g, 0), Vector2(g, size.y), GRID, 1.0)
		g += 48.0
	g = 0.0
	while g < size.y:
		draw_line(Vector2(0, g), Vector2(size.x, g), GRID, 1.0)
		g += 48.0

	var opening_count := 0
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		var x0 := float(a.get("x", 0))
		var y0 := float(a.get("y", 0))
		var x1 := float(b.get("x", 0))
		var y1 := float(b.get("y", 0))
		draw_line(_map(x0, y0, min_x, min_y, ox, oy, scale), _map(x1, y1, min_x, min_y, ox, oy, scale), WALL, 6.0)
		var length: float = max(Vector2(x1 - x0, y1 - y0).length(), 1.0)
		var ux := (x1 - x0) / length
		var uy := (y1 - y0) / length
		var openings: Array = w.get("openings", [])
		for op in openings:
			if typeof(op) != TYPE_DICTIONARY:
				continue
			opening_count += 1
			var kind := str(op.get("kind", "door"))
			var color := DOOR
			if kind == "window":
				color = WINDOW
			elif kind == "archway":
				color = ARCH
			var offset := float(op.get("offsetMm", 0))
			var width := float(op.get("widthMm", 0))
			var ax := x0 + ux * offset
			var ay := y0 + uy * offset
			var bx := ax + ux * width
			var by := ay + uy * width
			draw_line(_map(ax, ay, min_x, min_y, ox, oy, scale), _map(bx, by, min_x, min_y, ox, oy, scale), color, 8.0)

	var title := "方案 %s" % str(snapshot.get("id", "—"))
	if storey_height > 0:
		title += "  层高 %dmm" % int(storey_height)
	if not rooms.is_empty() and typeof(rooms[0]) == TYPE_DICTIONARY:
		var room: Dictionary = rooms[0]
		var name := str(room.get("name", room.get("id", "")))
		title += "  %s" % name
		if room.has("clearHeightMm"):
			title += " 净高 %dmm" % int(float(room.get("clearHeightMm", 0)))
	draw_string(_font(), Vector2(12, 28), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, LABEL)
	draw_string(
		_font(),
		Vector2(12, size.y - 14),
		"墙 · 门洞 · 窗洞 · 垭口  %d墙 %d洞" % [walls.size(), opening_count],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		LABEL
	)


func _map(x: float, y: float, min_x: float, min_y: float, ox: float, oy: float, scale: float) -> Vector2:
	# SceneIR Y up → canvas Y down.
	return Vector2(ox + (x - min_x) * scale, size.y - (oy + (y - min_y) * scale))


func _font() -> Font:
	return ThemeDB.fallback_font
