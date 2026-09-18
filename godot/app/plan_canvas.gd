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
	_draw_room_fills(rooms, walls, min_x, min_y, max_x, max_y, ox, oy, scale)
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		opening_count += _draw_wall(w, min_x, min_y, ox, oy, scale)

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


func _draw_room_fills(rooms: Array, walls: Array, min_x: float, min_y: float, max_x: float, max_y: float, ox: float, oy: float, scale: float) -> void:
	var palette: Array[Color] = [
		Color(0.98, 0.90, 0.70, 0.38),
		Color(0.86, 0.91, 0.97, 0.38),
		Color(0.91, 0.86, 0.80, 0.38),
		Color(0.88, 0.93, 0.86, 0.40),
		Color(0.94, 0.88, 0.92, 0.38),
		Color(0.90, 0.90, 0.86, 0.36),
	]
	var named: Array = []
	for room in rooms:
		if typeof(room) == TYPE_DICTIONARY:
			named.append(room)
	var pockets: Array = _flood_pockets(walls, min_x, min_y, max_x, max_y, ox, oy, scale)
	pockets.sort_custom(func(a, b): return float(a.get("area_m2", 0)) > float(b.get("area_m2", 0)))
	var used_names: Dictionary = {}
	var auto_i := 1
	for i in pockets.size():
		var pk: Dictionary = pockets[i]
		var poly: PackedVector2Array = pk.get("hull", PackedVector2Array())
		if poly.size() < 3:
			continue
		var fill: Color = palette[i % palette.size()]
		draw_colored_polygon(poly, fill)
		var c: Vector2 = pk.get("centroid", Vector2.ZERO)
		var area: float = float(pk.get("area_m2", 0))
		var name := _match_room_name(named, c, min_x, min_y, ox, oy, scale, used_names)
		if name.is_empty():
			name = "房间%d" % auto_i
			auto_i += 1
		else:
			used_names[name] = true
		var f := _font()
		var title := name
		var sub := "%.1f m²" % area
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(f, c - Vector2(tw * 0.5, 6), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Tokens.TEXT)
		var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(f, c - Vector2(sw * 0.5, -12), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Tokens.TEXT_SECONDARY)


func _match_room_name(rooms: Array, centroid: Vector2, min_x: float, min_y: float, ox: float, oy: float, scale: float, used: Dictionary) -> String:
	var best := ""
	var best_d := 90.0
	for room in rooms:
		var name := str(room.get("name", room.get("label", "")))
		if name.is_empty() or used.has(name):
			continue
		var pts: Array[Vector2] = []
		var ids: Array = room.get("wallIds", [])
		var walls: Array = []
		var storeys: Array = snapshot.get("storeys", [])
		if not storeys.is_empty() and typeof(storeys[0]) == TYPE_DICTIONARY:
			walls = storeys[0].get("walls", [])
		if ids.is_empty():
			continue
		var acc := Vector2.ZERO
		var n := 0
		for wid in ids:
			for w in walls:
				if typeof(w) != TYPE_DICTIONARY or str(w.get("id", "")) != str(wid):
					continue
				var a: Dictionary = w.get("start", {})
				var p := _map(float(a.get("x", 0)), float(a.get("y", 0)), min_x, min_y, ox, oy, scale)
				acc += p
				n += 1
				break
		if n <= 0:
			continue
		var rc := acc / float(n)
		var d: float = rc.distance_to(centroid)
		if d < best_d:
			best_d = d
			best = name
	return best


func _flood_pockets(walls: Array, min_x: float, min_y: float, max_x: float, max_y: float, ox: float, oy: float, scale: float) -> Array:
	var W := mini(int(size.x / 4.0), 180)
	var H := mini(int(size.y / 4.0), 180)
	W = maxi(W, 24)
	H = maxi(H, 24)
	var grid := PackedByteArray()
	grid.resize(W * H)
	grid.fill(0)
	var cell := Vector2(size.x / float(W), size.y / float(H))
	var stamp := func(p0: Vector2, p1: Vector2):
		var n: int = maxi(2, int(p0.distance_to(p1) / 2.0))
		for i in n + 1:
			var t: float = float(i) / float(n)
			var p: Vector2 = p0.lerp(p1, t)
			var gx := int(clampf(p.x / cell.x, 0.0, float(W - 1)))
			var gy := int(clampf(p.y / cell.y, 0.0, float(H - 1)))
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var xx := gx + dx
					var yy := gy + dy
					if xx >= 0 and yy >= 0 and xx < W and yy < H:
						grid[yy * W + xx] = 1
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		stamp.call(_map(float(a.get("x", 0)), float(a.get("y", 0)), min_x, min_y, ox, oy, scale),
			_map(float(b.get("x", 0)), float(b.get("y", 0)), min_x, min_y, ox, oy, scale))
	if grid[0] == 0:
		grid[0] = 2
	var stack: Array[int] = [0]
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not stack.is_empty():
		var cur: int = stack.pop_back()
		var cx: int = cur % W
		var cy: int = int(cur / W)
		for d in dirs:
			var nx: int = cx + d.x
			var ny: int = cy + d.y
			if nx < 0 or ny < 0 or nx >= W or ny >= H:
				continue
			var ni: int = ny * W + nx
			if grid[ni] != 0:
				continue
			grid[ni] = 2
			stack.append(ni)
	var seen := PackedByteArray()
	seen.resize(W * H)
	seen.fill(0)
	var pockets: Array = []
	var mm_per_cell: float = (cell.x / maxf(scale, 0.0001))
	for y in H:
		for x in W:
			var i: int = y * W + x
			if grid[i] != 0 or seen[i] != 0:
				continue
			var q: Array[int] = [i]
			seen[i] = 1
			var cells: Array[Vector2] = []
			var acc := Vector2.ZERO
			var head := 0
			while head < q.size():
				var cur2: int = q[head]
				head += 1
				var cx2: int = cur2 % W
				var cy2: int = int(cur2 / W)
				var p := Vector2((cx2 + 0.5) * cell.x, (cy2 + 0.5) * cell.y)
				cells.append(p)
				acc += p
				for d in dirs:
					var nx2: int = cx2 + d.x
					var ny2: int = cy2 + d.y
					if nx2 < 0 or ny2 < 0 or nx2 >= W or ny2 >= H:
						continue
					var ni2: int = ny2 * W + nx2
					if grid[ni2] != 0 or seen[ni2] != 0:
						continue
					seen[ni2] = 1
					q.append(ni2)
			var area_m2: float = float(cells.size()) * mm_per_cell * mm_per_cell / 1.0e6
			if area_m2 < 0.8 or cells.size() < 8:
				continue
			var hull := _convex_hull(cells)
			if hull.size() < 3:
				continue
			pockets.append({
				"centroid": acc / float(cells.size()),
				"area_m2": area_m2,
				"hull": hull,
			})
	return pockets


func _convex_hull(pts: Array[Vector2]) -> PackedVector2Array:
	if pts.size() < 3:
		return PackedVector2Array(pts)
	var sorted: Array[Vector2] = pts.duplicate()
	sorted.sort_custom(func(a, b): return a.x < b.x or (is_equal_approx(a.x, b.x) and a.y < b.y))
	var uniq: Array[Vector2] = []
	for p in sorted:
		if uniq.is_empty() or uniq[uniq.size() - 1].distance_to(p) > 0.5:
			uniq.append(p)
	if uniq.size() < 3:
		return PackedVector2Array(uniq)
	var lower: Array[Vector2] = []
	for p in uniq:
		while lower.size() >= 2 and _cross(lower[lower.size() - 2], lower[lower.size() - 1], p) <= 0.0:
			lower.pop_back()
		lower.append(p)
	var upper: Array[Vector2] = []
	for i in range(uniq.size() - 1, -1, -1):
		var p: Vector2 = uniq[i]
		while upper.size() >= 2 and _cross(upper[upper.size() - 2], upper[upper.size() - 1], p) <= 0.0:
			upper.pop_back()
		upper.append(p)
	lower.pop_back()
	upper.pop_back()
	var out := PackedVector2Array()
	for p in lower:
		out.append(p)
	for p in upper:
		out.append(p)
	return out


func _cross(o: Vector2, a: Vector2, b: Vector2) -> float:
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)


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
