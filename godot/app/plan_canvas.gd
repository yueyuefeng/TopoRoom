extends Control
## 户型图 canvas driven by SceneIR JSON (walls / 门窗洞 / 垭口). Not a mesh editor.

signal wall_clicked(wall_id)

var snapshot: Dictionary = {}
var show_chrome: bool = true
var interactive: bool = false
var selected_id: String = ""

var _map_min_x := 0.0
var _map_min_y := 0.0
var _map_ox := 0.0
var _map_oy := 0.0
var _map_scale := 1.0
var _segments: Array = []


func set_sceneir_json(text: String) -> void:
	snapshot = {}
	if not text.is_empty():
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			snapshot = parsed
	queue_redraw()


func _draw() -> void:
	_draw_paper()
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
		_draw_empty()
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
	var pad := 56.0
	var dx: float = max(max_x - min_x, 1.0)
	var dy: float = max(max_y - min_y, 1.0)
	var scale: float = min((size.x - 2.0 * pad) / dx, (size.y - 2.0 * pad) / dy)
	var ox: float = pad + ((size.x - 2.0 * pad) - dx * scale) * 0.5
	var oy: float = pad + ((size.y - 2.0 * pad) - dy * scale) * 0.5

	var opening_count := 0
	_segments.clear()
	_map_min_x = min_x
	_map_min_y = min_y
	_map_ox = ox
	_map_oy = oy
	_map_scale = scale
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		opening_count += _draw_wall(w, min_x, min_y, ox, oy, scale)

	_draw_rooms(rooms, walls, min_x, min_y, ox, oy, scale)
	if show_chrome:
		_draw_chrome(storey_height, rooms, walls.size(), opening_count)


func _draw_paper() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.PAPER)
	var step := 24.0
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), Tokens.GRID, 1.0)
		x += step
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Tokens.GRID, 1.0)
		y += step
	# faint frame
	draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Tokens.HAIRLINE, false, 1.0)


func _draw_empty() -> void:
	var f := _font()
	var msg := "还没有墙"
	var sub := "拍一张户型图，或从引导量房开始"
	draw_string(f, Vector2(24, size.y * 0.46), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Tokens.TEXT_SECONDARY)
	draw_string(f, Vector2(24, size.y * 0.46 + 26), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Tokens.DIM)


func _draw_wall(w: Dictionary, min_x: float, min_y: float, ox: float, oy: float, scale: float) -> int:
	var a: Dictionary = w.get("start", {})
	var b: Dictionary = w.get("end", {})
	var x0 := float(a.get("x", 0))
	var y0 := float(a.get("y", 0))
	var x1 := float(b.get("x", 0))
	var y1 := float(b.get("y", 0))
	var p0 := _map(x0, y0, min_x, min_y, ox, oy, scale)
	var p1 := _map(x1, y1, min_x, min_y, ox, oy, scale)
	var kind := str(w.get("kind", "exterior"))
	var stroke := Tokens.wall_stroke(kind)
	var thickness_mm := float(w.get("thicknessMm", 200))
	var width: float = clampf(6.0 + thickness_mm / 80.0, 7.0, 14.0)
	var wid := str(w.get("id", ""))
	_segments.append({"id": wid, "a": p0, "b": p1, "kind": kind})
	if selected_id == wid:
		draw_line(p0, p1, Tokens.PRIMARY_SOFT, width + 10.0)
	draw_line(p0, p1, stroke, width)
	_draw_dim(p0, p1, Vector2(x1 - x0, y1 - y0).length())

	var length: float = max(Vector2(x1 - x0, y1 - y0).length(), 1.0)
	var ux := (x1 - x0) / length
	var uy := (y1 - y0) / length
	var openings: Array = w.get("openings", [])
	var count := 0
	for op in openings:
		if typeof(op) != TYPE_DICTIONARY:
			continue
		count += 1
		var okind := str(op.get("kind", "door"))
		var color := Tokens.opening_stroke(okind)
		var offset := float(op.get("offsetMm", 0))
		var owidth := float(op.get("widthMm", 0))
		var ax := x0 + ux * offset
		var ay := y0 + uy * offset
		var bx := ax + ux * owidth
		var by := ay + uy * owidth
		var qa := _map(ax, ay, min_x, min_y, ox, oy, scale)
		var qb := _map(bx, by, min_x, min_y, ox, oy, scale)
		draw_line(qa, qb, Tokens.PAPER, width + 2.0)
		draw_line(qa, qb, color, width - 1.0)
		var mid := (qa + qb) * 0.5
		var n := Vector2(-(qb - qa).y, (qb - qa).x).normalized()
		if okind == "door":
			draw_line(qa, qa + n * 10.0, color, 1.5)
		elif okind == "window":
			draw_line(qa + n * 4.0, qb + n * 4.0, color, 1.5)
	return count


func _draw_dim(p0: Vector2, p1: Vector2, length_mm: float) -> void:
	var dir := p1 - p0
	if dir.length() < 8.0:
		return
	var n := Vector2(-dir.y, dir.x).normalized()
	var mid := (p0 + p1) * 0.5 + n * 14.0
	var tick := n * 5.0
	draw_line(p0, p0 + tick, Tokens.DIM, 1.0)
	draw_line(p1, p1 + tick, Tokens.DIM, 1.0)
	var txt := "%d" % int(round(length_mm))
	draw_string(_font(), mid + Vector2(-18, 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tokens.DIM)


func _draw_rooms(rooms: Array, walls: Array, min_x: float, min_y: float, ox: float, oy: float, scale: float) -> void:
	for room in rooms:
		if typeof(room) != TYPE_DICTIONARY:
			continue
		var name := str(room.get("name", room.get("label", room.get("id", ""))))
		if name.is_empty():
			continue
		var pts: Array[Vector2] = []
		var ids: Array = room.get("wallIds", [])
		if ids.is_empty():
			for w in walls:
				if typeof(w) == TYPE_DICTIONARY:
					var a: Dictionary = w.get("start", {})
					pts.append(_map(float(a.get("x", 0)), float(a.get("y", 0)), min_x, min_y, ox, oy, scale))
		else:
			for wid in ids:
				for w in walls:
					if typeof(w) == TYPE_DICTIONARY and str(w.get("id", "")) == str(wid):
						var a: Dictionary = w.get("start", {})
						pts.append(_map(float(a.get("x", 0)), float(a.get("y", 0)), min_x, min_y, ox, oy, scale))
						break
		if pts.is_empty():
			continue
		var c := Vector2.ZERO
		for p in pts:
			c += p
		c /= float(pts.size())
		var f := _font()
		var tw := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(f, c - Vector2(tw * 0.5, 0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Tokens.TEXT)


func _draw_chrome(storey_height: float, _rooms: Array, wall_n: int, opening_n: int) -> void:
	var f := _font()
	var title := "方案 %s" % str(snapshot.get("id", "—"))
	if storey_height > 0:
		title += "  ·  层高 %d mm" % int(storey_height)
	draw_string(f, Vector2(16, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Tokens.TEXT_SECONDARY)
	var items: Array = [
		["承重", Tokens.WALL_SHEAR],
		["砌体", Tokens.WALL_MASONRY],
		["门洞", Tokens.OPENING_DOOR],
		["窗洞", Tokens.OPENING_WINDOW],
		["垭口", Tokens.OPENING_ARCH],
	]
	var x := 16.0
	var y := size.y - 16.0
	for item in items:
		_swatch(Vector2(x, y - 4), item[1])
		x += 18.0
		draw_string(f, Vector2(x, y), str(item[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tokens.DIM)
		x += 36.0
	var tally := "%d墙 %d洞" % [wall_n, opening_n]
	draw_string(f, Vector2(size.x - 88, y), tally, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tokens.DIM)


func _swatch(pos: Vector2, color: Color) -> void:
	draw_line(pos, pos + Vector2(14, 0), color, 4.0)


func _map(x: float, y: float, min_x: float, min_y: float, ox: float, oy: float, scale: float) -> Vector2:
	# SceneIR Y up → canvas Y down.
	return Vector2(ox + (x - min_x) * scale, size.y - (oy + (y - min_y) * scale))


func _font() -> Font:
	if Studio and Studio.font:
		return Studio.font
	return ThemeDB.fallback_font


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var hit: String = _hit_wall(mb.position)
			if not hit.is_empty():
				selected_id = hit
				wall_clicked.emit(hit)
				queue_redraw()
				accept_event()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			var hit2: String = _hit_wall(st.position)
			if not hit2.is_empty():
				selected_id = hit2
				wall_clicked.emit(hit2)
				queue_redraw()
				accept_event()


func _hit_wall(pos: Vector2) -> String:
	var best: String = ""
	var best_d: float = 18.0
	for seg in _segments:
		if typeof(seg) != TYPE_DICTIONARY:
			continue
		var d: float = _dist_seg(pos, seg.a, seg.b)
		if d < best_d:
			best_d = d
			best = str(seg.get("id", ""))
	return best


func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = 0.0
	var denom: float = ab.length_squared()
	if denom > 0.0001:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)
