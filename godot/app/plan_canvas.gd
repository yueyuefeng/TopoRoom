extends Control
## 户型图 canvas driven by SceneIR JSON (walls / 门窗洞 / 垭口). Not a mesh editor.

signal wall_clicked(wall_id)
signal opening_clicked(opening_id, wall_id)

var snapshot: Dictionary = {}
var show_chrome: bool = true
var joyplan_look: bool = false
var interactive: bool = false
var selected_id: String = ""
var selected_opening_id: String = ""
var drop_preview: Dictionary = {}

var _map_min_x := 0.0
var _map_min_y := 0.0
var _map_ox := 0.0
var _map_oy := 0.0
var _map_scale := 1.0
var _reg_active := false
var _reg_mm := 0.0
var _reg_origin := Vector2.ZERO
var _reg_img := Vector2.ZERO
var _segments: Array = []
var _openings: Array = []
var _photo: Texture2D
var _photo_img: Image


func set_sceneir_json(text: String) -> void:
	snapshot = {}
	if not text.is_empty():
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			snapshot = parsed
	queue_redraw()


func load_photo(path: String) -> void:
	var img := Image.new()
	var candidates: Array[String] = [path]
	if path.begins_with("user://") or path.begins_with("res://"):
		candidates.append(ProjectSettings.globalize_path(path))
	var ok := false
	for p in candidates:
		if p.is_empty():
			continue
		var buf := FileAccess.get_file_as_bytes(p)
		if buf.size() >= 32:
			var ext := p.get_extension().to_lower()
			if ext == "png" and img.load_png_from_buffer(buf) == OK:
				ok = true
				break
			if (ext == "jpg" or ext == "jpeg") and img.load_jpg_from_buffer(buf) == OK:
				ok = true
				break
		if img.load(p) == OK:
			ok = true
			break
	if not ok:
		return
	_photo_img = img
	_photo = ImageTexture.create_from_image(img)
	queue_redraw()


func _photo_ink_ratio(p0: Vector2, p1: Vector2) -> float:
	if _photo_img == null:
		return 1.0
	var cover := _photo_cover_rect()
	if cover.size.x < 1.0 or cover.size.y < 1.0:
		return 1.0
	var iw := _photo_img.get_width()
	var ih := _photo_img.get_height()
	var n := maxi(6, int(p0.distance_to(p1) / 3.0))
	var hits := 0
	var tot := 0
	for i in n + 1:
		var p: Vector2 = p0.lerp(p1, float(i) / float(n))
		var q: Vector2 = (p - cover.position) / cover.size * Vector2(iw, ih)
		var x := int(floor(q.x))
		var y := int(floor(q.y))
		if x < 0 or y < 0 or x >= iw or y >= ih:
			continue
		tot += 1
		var c: Color = _photo_img.get_pixel(x, y)
		var lu := 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
		# Black shear + grey envelope strokes on the gold plan.
		if lu < 0.62:
			hits += 1
	if tot < 4:
		return 0.0
	return float(hits) / float(tot)


func _photo_cover_rect() -> Rect2:
	if _photo == null:
		return Rect2(Vector2.ZERO, size)
	var tex: Vector2 = _photo.get_size()
	if tex.x < 1.0 or tex.y < 1.0:
		return Rect2(Vector2.ZERO, size)
	var s := maxf(size.x / tex.x, size.y / tex.y)
	var d := tex * s
	return Rect2((size - d) * 0.5, d)


func _vision_registration() -> Dictionary:
	var vis: Dictionary = Session.last_vision if typeof(Session.last_vision) == TYPE_DICTIONARY else {}
	var mm := float(vis.get("mm_per_px", 0))
	if mm < 0.05:
		mm = Session.last_scale_mm_per_px
	var origin := Vector2(float(vis.get("origin_x_px", 0)), float(vis.get("origin_y_px", 0)))
	var img_w := float(vis.get("image_width", 0))
	var img_h := float(vis.get("image_height", 0))
	if _photo:
		if img_w < 8.0:
			img_w = _photo.get_width()
		if img_h < 8.0:
			img_h = _photo.get_height()
	if not vis.has("origin_x_px") or not vis.has("origin_y_px") or int(vis.get("image_width", 0)) < 8:
		return {}
	if not joyplan_look or _photo == null or mm < 0.05 or img_w < 8.0 or img_h < 8.0:
		return {}
	if str(vis.get("adapter", "")) == "fake":
		return {}
	return {"mm": mm, "origin": origin, "img": Vector2(img_w, img_h)}


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

	var reg := _vision_registration()
	_reg_active = not reg.is_empty()
	if _reg_active:
		_reg_mm = float(reg.get("mm", 0))
		_reg_origin = reg.get("origin", Vector2.ZERO)
		_reg_img = reg.get("img", Vector2.ZERO)
		var cover := _photo_cover_rect()
		var s := cover.size.x / maxf(_reg_img.x, 1.0)
		_map_scale = s / maxf(_reg_mm, 0.05)
		_map_ox = cover.position.x
		_map_oy = cover.position.y
	else:
		_reg_mm = 0.0
		_reg_origin = Vector2.ZERO
		_reg_img = Vector2.ZERO

	var opening_count := 0
	_segments.clear()
	_openings.clear()
	_map_min_x = min_x
	_map_min_y = min_y
	if not _reg_active:
		_map_ox = ox
		_map_oy = oy
		_map_scale = scale
	_draw_room_fills(rooms, walls, min_x, min_y, max_x, max_y, ox, oy, scale)
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		opening_count += _draw_wall(w, min_x, min_y, ox, oy, scale)
	_draw_drop_preview()

	if show_chrome:
		_draw_chrome(storey_height, rooms, walls.size(), opening_count)


func _draw_paper() -> void:
	if joyplan_look:
		if _photo:
			var tex_size: Vector2 = _photo.get_size()
			if tex_size.x > 1.0 and tex_size.y > 1.0:
				var s := maxf(size.x / tex_size.x, size.y / tex_size.y)
				var d := tex_size * s
				var o := (size - d) * 0.5
				draw_texture_rect(_photo, Rect2(o, d), false)
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.78, 0.86, 0.12))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.98, 0.94, 0.95, 1))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Tokens.PAPER)
	if Session.ruler_on("grid") and not joyplan_look:
		var step := 24.0
		var x := 0.0
		while x < size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), Tokens.GRID, 1.0)
			x += step
		var y := 0.0
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), Tokens.GRID, 1.0)
			y += step
	if not joyplan_look:
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
	var stroke := Tokens.WALL_JOY if joyplan_look else Tokens.wall_stroke(kind)
	var thickness_mm := float(w.get("thicknessMm", 200))
	var width: float = clampf(6.0 + thickness_mm / 80.0, 7.0, 14.0)
	if joyplan_look:
		width = clampf(8.0 + thickness_mm / 70.0, 8.0, 16.0)
		if _reg_active and _photo:
			var cover := _photo_cover_rect()
			var px_per_mm := (cover.size.x / maxf(_reg_img.x, 1.0)) / maxf(_reg_mm, 0.05)
			width = clampf(thickness_mm * px_per_mm, 5.0, 18.0)
	var wid := str(w.get("id", ""))
	var length: float = max(Vector2(x1 - x0, y1 - y0).length(), 1.0)
	_segments.append({
		"id": wid, "a": p0, "b": p1, "kind": kind,
		"x0": x0, "y0": y0, "x1": x1, "y1": y1,
		"length_mm": length, "thickness_mm": thickness_mm,
		"height_mm": float(w.get("heightMm", 2800)),
	})
	if selected_id == wid and selected_opening_id.is_empty():
		draw_line(p0, p1, Tokens.PAGE_SELECT, width + 12.0)
		draw_line(p0, p1, Tokens.PAGE_SELECT, width + 2.0)
		if joyplan_look:
			var mid: Vector2 = p0.lerp(p1, 0.55)
			draw_circle(mid, 13.0, Tokens.PAGE_SELECT)
			draw_circle(mid, 13.0, Color.WHITE, false, 1.2)
			var fnt := _font()
			draw_string(fnt, mid + Vector2(-5, 5), "L", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	elif joyplan_look and _photo:
		var ink := _photo_ink_ratio(p0, p1)
		if ink >= 0.48:
			var alpha := clampf(0.50 + ink * 0.42, 0.50, 0.92)
			draw_line(p0, p1, Color(0.07, 0.07, 0.09, alpha), width)
	else:
		draw_line(p0, p1, stroke, width)
	if Tokens.is_load_bearing_kind(kind) and not joyplan_look:
		_draw_shear_hatch(p0, p1, width, stroke)
	if not joyplan_look:
		_draw_dim(p0, p1, length)

	var ux := (x1 - x0) / length
	var uy := (y1 - y0) / length
	var openings: Array = w.get("openings", [])
	var count := 0
	for op in openings:
		if typeof(op) != TYPE_DICTIONARY:
			continue
		count += 1
		var okind := str(op.get("kind", "door"))
		var oid := str(op.get("id", ""))
		var color := Tokens.opening_stroke(okind)
		var offset := float(op.get("offsetMm", 0))
		var owidth := float(op.get("widthMm", 0))
		var oheight := float(op.get("heightMm", 2100))
		var ax := x0 + ux * offset
		var ay := y0 + uy * offset
		var bx := ax + ux * owidth
		var by := ay + uy * owidth
		var qa := _map(ax, ay, min_x, min_y, ox, oy, scale)
		var qb := _map(bx, by, min_x, min_y, ox, oy, scale)
		_openings.append({
			"id": oid, "wall_id": wid, "kind": okind,
			"a": qa, "b": qb, "width_mm": owidth, "height_mm": oheight,
			"offset_mm": offset, "sill_mm": float(op.get("sillHeightMm", 0)),
		})
		if selected_opening_id == oid:
			draw_line(qa, qb, Tokens.PAGE_SELECT, width + 8.0)
		if joyplan_look and _photo:
			if _photo_ink_ratio(p0, p1) >= 0.48:
				draw_line(qa, qb, Color(1, 1, 1, 0.45), maxf(width - 2.0, 3.0))
		else:
			draw_line(qa, qb, Tokens.PAPER, width + 2.0)
			draw_line(qa, qb, color, width - 1.0)
			var n := Vector2(-(qb - qa).y, (qb - qa).x).normalized()
			if okind == "door":
				if Session.ruler_on("opening"):
					var swing := Session.swing_for(oid)
					var hinge: Vector2 = qa if swing > 0 else qb
					var nn := n * (10.0 * float(swing))
					draw_line(hinge, hinge + nn, color, 1.5)
			elif okind == "window":
				if Session.ruler_on("opening"):
					draw_line(qa + n * 4.0, qb + n * 4.0, color, 1.5)
	return count


func _draw_shear_hatch(p0: Vector2, p1: Vector2, width: float, color: Color) -> void:
	var dir: Vector2 = p1 - p0
	var length: float = dir.length()
	if length < 10.0:
		return
	var u: Vector2 = dir / length
	var n := Vector2(-u.y, u.x)
	var tick := n * (width * 0.62)
	var slant: Vector2 = u * 3.2
	var ink := Color(color.r * 0.55, color.g * 0.42, color.b * 0.38, 0.95)
	var t := 5.0
	var step := maxf(6.0, width * 0.85)
	while t < length - 4.0:
		var p: Vector2 = p0 + u * t
		draw_line(p - tick - slant, p + tick + slant, ink, 1.6)
		t += step


func _draw_dim(p0: Vector2, p1: Vector2, length_mm: float) -> void:
	if not Session.ruler_on("wall_len"):
		return
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
	if joyplan_look and _photo:
		return
	var palette: Array[Color] = [
		Color(0.93, 0.93, 0.94, 0.50),
		Color(0.96, 0.90, 0.82, 0.42),
		Color(0.90, 0.92, 0.95, 0.42),
		Color(0.92, 0.94, 0.90, 0.42),
		Color(0.94, 0.90, 0.92, 0.40),
		Color(0.91, 0.91, 0.88, 0.40),
	]
	if not joyplan_look:
		palette = [
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
		if joyplan_look and not selected_id.is_empty() and _pocket_touches_selected(poly):
			fill = Tokens.PAGE_ORANGE
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
		var show_area := Session.ruler_on("room_area")
		var sub := _format_area_m2(area) if show_area else ""
		var title_size := 17
		var sub_size := 13
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
		var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size).x if show_area else 0.0
		if joyplan_look:
			draw_string(f, Vector2(c.x - tw * 0.5, c.y - (4 if show_area else -2)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Tokens.TEXT)
			if show_area:
				draw_string(f, Vector2(c.x - sw * 0.5, c.y + 14), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Tokens.TEXT_SECONDARY)
		else:
			var bw := maxf(tw, sw) + 20.0
			var bh := 38.0 if show_area else 26.0
			var box := Rect2(c - Vector2(bw * 0.5, 22.0 if show_area else 14.0), Vector2(bw, bh))
			draw_rect(box, Color(1, 1, 1, 0.82), true)
			draw_rect(box, Tokens.HAIRLINE, false, 1.0)
			draw_string(f, Vector2(c.x - tw * 0.5, c.y - (4 if show_area else -2)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Tokens.TEXT)
			if show_area:
				draw_string(f, Vector2(c.x - sw * 0.5, c.y + 14), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Tokens.TEXT_SECONDARY)


func _pocket_touches_selected(poly: PackedVector2Array) -> bool:
	for seg in _segments:
		if typeof(seg) != TYPE_DICTIONARY:
			continue
		if str(seg.get("id", "")) != selected_id:
			continue
		var mid: Vector2 = (seg.a + seg.b) * 0.5
		if Geometry2D.is_point_in_polygon(mid, poly):
			return true
		if mid.distance_to(_poly_centroid(poly)) < 80.0:
			return true
	return false


func _poly_centroid(poly: PackedVector2Array) -> Vector2:
	var acc := Vector2.ZERO
	for p in poly:
		acc += p
	return acc / float(maxi(poly.size(), 1))


func selected_anchor() -> Vector2:
	if not selected_opening_id.is_empty():
		for op in _openings:
			if typeof(op) == TYPE_DICTIONARY and str(op.get("id", "")) == selected_opening_id:
				return (op.a + op.b) * 0.5
	for seg in _segments:
		if typeof(seg) == TYPE_DICTIONARY and str(seg.get("id", "")) == selected_id:
			return (seg.a + seg.b) * 0.5
	return size * 0.5


func _format_area_m2(area: float) -> String:
	if area >= 10.0:
		return "%d m²" % int(round(area))
	return "%.1f m²" % area


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
	if _reg_active and _reg_mm >= 0.05 and _photo:
		var cover := _photo_cover_rect()
		var tex: Vector2 = _photo.get_size()
		var vis_img: Vector2 = _reg_img if _reg_img.x >= 8.0 else tex
		# Vision origin + mm_per_px are in the analyzed SOURCE image. Scale that
		# into the displayed texture, then into KEEP_ASPECT COVER of this canvas.
		var px := _reg_origin.x + x / _reg_mm
		var py := _reg_origin.y - y / _reg_mm
		px *= tex.x / maxf(vis_img.x, 1.0)
		py *= tex.y / maxf(vis_img.y, 1.0)
		var s := cover.size.x / maxf(tex.x, 1.0)
		return cover.position + Vector2(px, py) * s
	# SceneIR Y up → canvas Y down.
	return Vector2(ox + (x - min_x) * scale, size.y - (oy + (y - min_y) * scale))


func _font() -> Font:
	if Studio and Studio.font:
		return Studio.font
	return ThemeDB.fallback_font


func set_drop_preview(kind: String, canvas_pos: Vector2) -> Dictionary:
	drop_preview = snap_opening(canvas_pos, kind)
	queue_redraw()
	return drop_preview


func clear_drop_preview() -> void:
	if drop_preview.is_empty():
		return
	drop_preview = {}
	queue_redraw()


func nearest_wall(pos: Vector2, max_px: float = 56.0) -> Dictionary:
	var best := {}
	var best_d := max_px
	for seg in _segments:
		if typeof(seg) != TYPE_DICTIONARY:
			continue
		var a: Vector2 = seg.a
		var b: Vector2 = seg.b
		var d: float = _dist_seg(pos, a, b)
		if d >= best_d:
			continue
		best_d = d
		var ab: Vector2 = b - a
		var t := 0.0
		var denom: float = ab.length_squared()
		if denom > 0.0001:
			t = clampf((pos - a).dot(ab) / denom, 0.0, 1.0)
		var length_mm := float(seg.get("length_mm", 1.0))
		best = {
			"id": str(seg.get("id", "")),
			"kind": str(seg.get("kind", "")),
			"offset_mm": t * length_mm,
			"length_mm": length_mm,
			"thickness_mm": float(seg.get("thickness_mm", 200)),
			"height_mm": float(seg.get("height_mm", 2800)),
			"dist": d,
			"point": a.lerp(b, t),
			"a": a,
			"b": b,
			"t": t,
		}
	return best


func snap_opening(pos: Vector2, kind: String, max_px: float = 56.0) -> Dictionary:
	var hit: Dictionary = nearest_wall(pos, max_px)
	if hit.is_empty():
		return {}
	var width := 900.0
	if kind == "window" or kind == "archway":
		width = 1200.0
	var length := float(hit.get("length_mm", 1.0))
	var off := clampf(float(hit.get("offset_mm", 0)) - width * 0.5, 0.0, maxf(length - width, 0.0))
	hit["offset_mm"] = off
	hit["width_mm"] = width
	hit["opening_kind"] = kind
	return hit


func wall_metrics(wall_id: String) -> Dictionary:
	for seg in _segments:
		if typeof(seg) == TYPE_DICTIONARY and str(seg.get("id", "")) == wall_id:
			return {
				"id": wall_id,
				"length_mm": float(seg.get("length_mm", 0)),
				"thickness_mm": float(seg.get("thickness_mm", 200)),
				"height_mm": float(seg.get("height_mm", 2800)),
				"kind": str(seg.get("kind", "")),
			}
	return {}


func opening_metrics(opening_id: String) -> Dictionary:
	for op in _openings:
		if typeof(op) == TYPE_DICTIONARY and str(op.get("id", "")) == opening_id:
			return op
	return {}


func to_canvas(global_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_pos


func _draw_drop_preview() -> void:
	if drop_preview.is_empty():
		return
	var kind := str(drop_preview.get("opening_kind", "door"))
	var color := Tokens.opening_stroke(kind)
	var a: Vector2 = drop_preview.get("a", Vector2.ZERO)
	var b: Vector2 = drop_preview.get("b", Vector2.ZERO)
	var length := float(drop_preview.get("length_mm", 1.0))
	if length < 1.0:
		return
	draw_line(a, b, Tokens.PRIMARY_SOFT, 18.0)
	draw_line(a, b, Color(Tokens.PRIMARY.r, Tokens.PRIMARY.g, Tokens.PRIMARY.b, 0.55), 8.0)
	var t0 := float(drop_preview.get("offset_mm", 0)) / length
	var t1 := (float(drop_preview.get("offset_mm", 0)) + float(drop_preview.get("width_mm", 900))) / length
	var qa: Vector2 = a.lerp(b, clampf(t0, 0.0, 1.0))
	var qb: Vector2 = a.lerp(b, clampf(t1, 0.0, 1.0))
	draw_line(qa, qb, Color(color.r, color.g, color.b, 0.28), 16.0)
	draw_line(qa, qb, color, 6.0)
	draw_circle(qa, 5.0, color)
	draw_circle(qb, 5.0, color)
	var n := Vector2(-(b - a).y, (b - a).x).normalized()
	_draw_drag_dim(a, qa, n, Color(0.12, 0.12, 0.14), float(drop_preview.get("offset_mm", 0)))
	var rest := float(drop_preview.get("length_mm", 1)) - float(drop_preview.get("offset_mm", 0)) - float(drop_preview.get("width_mm", 900))
	_draw_drag_dim(qb, b, n, Tokens.DANGER, rest)
	var label := Tokens.opening_label(kind)
	draw_string(_font(), (qa + qb) * 0.5 + Vector2(-18, -10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)


func _draw_drag_dim(p0: Vector2, p1: Vector2, n: Vector2, ink: Color, mm: float) -> void:
	if p0.distance_to(p1) < 10.0:
		return
	var a: Vector2 = p0 + n * 12.0
	var b: Vector2 = p1 + n * 12.0
	draw_line(p0, a, ink, 1.0)
	draw_line(p1, b, ink, 1.0)
	draw_line(a, b, ink, 1.4)
	var txt := "%d" % int(round(mm))
	draw_string(_font(), (a + b) * 0.5 + Vector2(-14, -4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pos = mb.position
			pressed = true
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			pos = st.position
			pressed = true
	if not pressed:
		return
	var oid: String = _hit_opening(pos)
	if not oid.is_empty():
		selected_opening_id = oid
		var op: Dictionary = opening_metrics(oid)
		selected_id = str(op.get("wall_id", ""))
		opening_clicked.emit(oid, selected_id)
		queue_redraw()
		accept_event()
		return
	var hit: String = _hit_wall(pos)
	if not hit.is_empty():
		selected_id = hit
		selected_opening_id = ""
		wall_clicked.emit(hit)
		queue_redraw()
		accept_event()


func _hit_opening(pos: Vector2) -> String:
	var best := ""
	var best_d := 16.0
	for op in _openings:
		if typeof(op) != TYPE_DICTIONARY:
			continue
		var d: float = _dist_seg(pos, op.a, op.b)
		if d < best_d:
			best_d = d
			best = str(op.get("id", ""))
	return best


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
