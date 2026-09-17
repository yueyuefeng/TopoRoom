extends Node3D
## Command-synced 3D edit. Meshes/gizmos are InteractionShell; millimetres live in SceneIR.
## Dragged triangle vertices are never written back. Lighting is Visualization-only.

const Lighting := preload("res://app/lighting.gd")

const KIND_WALL := "wall"
const KIND_OPENING := "opening"
const KIND_HOSTED := "hosted"
const HANDLE_WALL_END := "wall_end"
const HANDLE_WALL_HEIGHT := "wall_height"
const HANDLE_OPENING_OFFSET := "opening_offset"
const HANDLE_OPENING_WIDTH := "opening_width"
const HANDLE_STOREY_HEIGHT := "storey_height"

var _lighting: Node3D
var _camera: Camera3D
var _solids: Node3D
var _gizmos: Node3D
var _status: Label
var _sel_label: Label
var _cjk: Font

var _yaw := 0.55
var _pitch := -0.48
var _distance := 11.0
var _orbiting := false
var _target := Vector3(2.0, 1.1, 1.5)

var _snapshot: Dictionary = {}
var _selected: Dictionary = {}
var _drag: Dictionary = {}
var _built_json := ""


func _ready() -> void:
	_cjk = _system_cjk()
	_lighting = Lighting.new()
	_lighting.name = "Lighting"
	add_child(_lighting)

	_camera = Camera3D.new()
	_camera.current = true
	add_child(_camera)

	_solids = Node3D.new()
	_solids.name = "Solids"
	add_child(_solids)
	_gizmos = Node3D.new()
	_gizmos.name = "Gizmos"
	add_child(_gizmos)

	_build_hud()
	Session.document_changed.connect(_on_document_changed)
	if Session.has_core():
		Session.last_rebuild = Session.rebuild_probe()
	_refresh_world(true)
	_orbit()


func _system_cjk() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Noto Sans CJK SC", "Noto Sans CJK", "Source Han Sans SC",
		"DroidSansFallback", "Noto Sans SC", "WenQuanYi Micro Hei", "sans-serif",
	])
	return font


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var col := VBoxContainer.new()
	col.offset_left = 16
	col.offset_top = 16
	col.add_theme_constant_override("separation", 8)
	layer.add_child(col)
	_status = _hud_label("", 15)
	_status.custom_minimum_size = Vector2(520, 0)
	col.add_child(_status)
	_sel_label = _hud_label("", 14)
	_sel_label.custom_minimum_size = Vector2(520, 0)
	col.add_child(_sel_label)
	col.add_child(_hud_btn("返回户型图", func(): get_tree().change_scene_to_file("res://app/main.tscn")))
	col.add_child(_hud_btn("白天 / 暖光", func(): _lighting.toggle_preset(); _update_hud()))
	col.add_child(_hud_btn("加载夹具样例", func(): Session.load_fixture_json("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json")))
	col.add_child(_hud_label("左键选择/拖动手柄 · 右键旋转 · 滚轮缩放。提交后经 C API 写回 SceneIR。", 12))


func _hud_label(text: String, size_px: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _cjk)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", Color(0.95, 0.95, 0.93))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _hud_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 40)
	b.add_theme_font_override("font", _cjk)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b


func _on_document_changed() -> void:
	_refresh_world(not Session.keep_preview)


func _solids_json() -> String:
	if Session.keep_preview and not Session.preview_sceneir_json.is_empty():
		return Session.preview_sceneir_json
	return Session.sceneir_json()


func _refresh_world(rebuild_solids: bool) -> void:
	var json := _solids_json()
	if rebuild_solids or json != _built_json:
		_snapshot = _parse(json)
		_clear(_solids)
		_build_solids()
		_built_json = json
		_retarget()
	_clear(_gizmos)
	_build_gizmos()
	_update_hud()
	_orbit()


func _parse(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


func _storey() -> Dictionary:
	var storeys: Array = _snapshot.get("storeys", [])
	if storeys.is_empty() or typeof(storeys[0]) != TYPE_DICTIONARY:
		return {}
	return storeys[0]


func _walls() -> Array:
	return _storey().get("walls", [])


func _retarget() -> void:
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	var h := 2.8
	for w in _walls():
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		min_x = min(min_x, min(float(a.get("x", 0)), float(b.get("x", 0))))
		min_y = min(min_y, min(float(a.get("y", 0)), float(b.get("y", 0))))
		max_x = max(max_x, max(float(a.get("x", 0)), float(b.get("x", 0))))
		max_y = max(max_y, max(float(a.get("y", 0)), float(b.get("y", 0))))
		h = max(h, float(w.get("heightMm", 2800)) / 1000.0)
	if min_x == INF:
		_target = Vector3(2.0, 1.1, 1.5)
		return
	_target = Vector3((min_x + max_x) * 0.0005, h * 0.35, (min_y + max_y) * 0.0005)


func _build_solids() -> void:
	var walls: Array = _walls()
	if walls.is_empty():
		return
	_add_floor(walls)
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		_add_wall_mesh(w)
	for hc in _storey().get("hostedComponents", []):
		if typeof(hc) == TYPE_DICTIONARY:
			_add_hosted(hc, walls)


func _add_floor(walls: Array) -> void:
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for w in walls:
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		min_x = min(min_x, min(float(a.get("x", 0)), float(b.get("x", 0))))
		min_y = min(min_y, min(float(a.get("y", 0)), float(b.get("y", 0))))
		max_x = max(max_x, max(float(a.get("x", 0)), float(b.get("x", 0))))
		max_y = max(max_y, max(float(a.get("y", 0)), float(b.get("y", 0))))
	var sx := max((max_x - min_x) / 1000.0, 0.5)
	var sz := max((max_y - min_y) / 1000.0, 0.5)
	var pos := Vector3((min_x + max_x) * 0.0005, -0.02, (min_y + max_y) * 0.0005)
	_add_box(_solids, Vector3(sx + 0.4, 0.04, sz + 0.4), pos, Basis.IDENTITY, _lighting.floor_material(), {})


func _frame(w: Dictionary) -> Dictionary:
	var a: Dictionary = w.get("start", {})
	var b: Dictionary = w.get("end", {})
	var x0 := float(a.get("x", 0))
	var y0 := float(a.get("y", 0))
	var x1 := float(b.get("x", 0))
	var y1 := float(b.get("y", 0))
	var length: float = max(Vector2(x1 - x0, y1 - y0).length(), 1.0)
	return {
		"id": str(w.get("id", "")),
		"x0": x0, "y0": y0, "x1": x1, "y1": y1,
		"length": length,
		"ux": (x1 - x0) / length,
		"uy": (y1 - y0) / length,
		"thickness": float(w.get("thicknessMm", 200)),
		"height": float(w.get("heightMm", 2800)),
		"openings": w.get("openings", []),
	}


func _add_wall_mesh(w: Dictionary) -> void:
	var f := _frame(w)
	var cuts: Array = [{"t": 0.0, "w": 0.0, "h": 0.0, "sill": 0.0, "op": null}]
	for op in f.openings:
		if typeof(op) != TYPE_DICTIONARY:
			continue
		cuts.append({
			"t": float(op.get("offsetMm", 0)),
			"w": float(op.get("widthMm", 0)),
			"h": float(op.get("heightMm", 0)),
			"sill": float(op.get("sillHeightMm", 0)),
			"op": op,
		})
	cuts.sort_custom(func(a, b): return float(a.t) < float(b.t))
	var cursor := 0.0
	var wall_h: float = f.height
	var wall_mat: Material = _lighting.wall_material()
	var meta_wall := {"pick": KIND_WALL, "wall_id": f.id}
	for cut in cuts:
		if cut.op == null:
			continue
		var t0: float = float(cut.t)
		var t1: float = t0 + float(cut.w)
		if t0 > cursor + 4.0:
			_add_wall_span(f, cursor, t0, 0.0, wall_h, wall_mat, meta_wall)
		var sill: float = float(cut.sill)
		var oh: float = float(cut.h)
		if sill > 4.0:
			_add_wall_span(f, t0, t1, 0.0, sill, wall_mat, meta_wall)
		if sill + oh < wall_h - 4.0:
			_add_wall_span(f, t0, t1, sill + oh, wall_h, wall_mat, meta_wall)
		_add_opening_volume(f, cut.op)
		cursor = max(cursor, t1)
	if cursor < f.length - 4.0:
		_add_wall_span(f, cursor, f.length, 0.0, wall_h, wall_mat, meta_wall)


func _wall_basis(f: Dictionary) -> Basis:
	var dir := Vector3(f.ux, 0.0, f.uy)
	if dir.length() < 0.001:
		return Basis.IDENTITY
	return Basis.looking_at(dir, Vector3.UP)


func _add_wall_span(f: Dictionary, t0: float, t1: float, z0: float, z1: float, mat: Material, meta: Dictionary) -> void:
	var span: float = t1 - t0
	var rise: float = z1 - z0
	if span < 4.0 or rise < 4.0:
		return
	var tm := (t0 + t1) * 0.5
	var pos := Vector3((f.x0 + f.ux * tm) / 1000.0, (z0 + z1) * 0.0005, (f.y0 + f.uy * tm) / 1000.0)
	var size := Vector3(f.thickness / 1000.0, rise / 1000.0, span / 1000.0)
	_add_box(_solids, size, pos, _wall_basis(f), mat, meta)


func _add_opening_volume(f: Dictionary, op: Dictionary) -> void:
	var kind := str(op.get("kind", "door"))
	var oid := str(op.get("id", ""))
	var selected := _selected.get("pick", "") == KIND_OPENING and str(_selected.get("opening_id", "")) == oid
	var offset := float(op.get("offsetMm", 0))
	var width := float(op.get("widthMm", 0))
	var height := float(op.get("heightMm", 0))
	var sill := float(op.get("sillHeightMm", 0))
	var tm := offset + width * 0.5
	var pos := Vector3(
		(f.x0 + f.ux * tm) / 1000.0,
		(sill + height * 0.5) / 1000.0,
		(f.y0 + f.uy * tm) / 1000.0
	)
	var size := Vector3(max(f.thickness / 1000.0 * 1.15, 0.08), max(height / 1000.0, 0.1), max(width / 1000.0, 0.1))
	var meta := {
		"pick": KIND_OPENING,
		"wall_id": f.id,
		"opening_id": oid,
		"kind": kind,
	}
	_add_box(_solids, size, pos, _wall_basis(f), _lighting.opening_material(kind, selected), meta)


func _add_hosted(hc: Dictionary, walls: Array) -> void:
	var hid := str(hc.get("id", ""))
	var kind := str(hc.get("kind", "beam"))
	var params: Dictionary = hc.get("params", hc)
	var z_bottom := float(params.get("zBottomMm", hc.get("zBottomMm", 0)))
	var depth := float(params.get("depthMm", hc.get("depthMm", 300)))
	var host_id := str(hc.get("hostWallId", ""))
	var f: Dictionary = {}
	for w in walls:
		if typeof(w) == TYPE_DICTIONARY and str(w.get("id", "")) == host_id:
			f = _frame(w)
			break
	if f.is_empty() and not walls.is_empty() and typeof(walls[0]) == TYPE_DICTIONARY:
		f = _frame(walls[0])
	if f.is_empty():
		return
	var pos := Vector3((f.x0 + f.x1) * 0.0005, (z_bottom + depth * 0.5) / 1000.0, (f.y0 + f.y1) * 0.0005)
	var size := Vector3(max(f.thickness / 1000.0 * 1.4, 0.12), max(depth / 1000.0, 0.12), max(f.length / 1000.0 * 0.7, 0.4))
	_add_box(_solids, size, pos, _wall_basis(f), _lighting.hosted_material(), {
		"pick": KIND_HOSTED, "hosted_id": hid, "kind": kind, "wall_id": f.id,
	})


func _build_gizmos() -> void:
	var walls: Array = _walls()
	if walls.is_empty():
		return
	var storey_h := float(_storey().get("heightMm", 2800))
	var corner := _first_corner(walls)
	_add_handle(
		_gizmos,
		Vector3(corner.x / 1000.0, storey_h / 1000.0, corner.y / 1000.0),
		0.16,
		HANDLE_STOREY_HEIGHT,
		{"pick": HANDLE_STOREY_HEIGHT, "height_mm": storey_h},
		false
	)
	var sel_wall := str(_selected.get("wall_id", ""))
	var sel_op := str(_selected.get("opening_id", ""))
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var f := _frame(w)
		var is_wall := _selected.get("pick", "") == KIND_WALL and f.id == sel_wall
		var wall_hot := is_wall or sel_wall == f.id
		_add_handle(_gizmos, Vector3(f.x0 / 1000.0, f.height * 0.0005, f.y0 / 1000.0), 0.13, HANDLE_WALL_END, {
			"pick": HANDLE_WALL_END, "wall_id": f.id, "end": "start", "x_mm": f.x0, "y_mm": f.y0,
		}, wall_hot)
		_add_handle(_gizmos, Vector3(f.x1 / 1000.0, f.height * 0.0005, f.y1 / 1000.0), 0.13, HANDLE_WALL_END, {
			"pick": HANDLE_WALL_END, "wall_id": f.id, "end": "end", "x_mm": f.x1, "y_mm": f.y1,
		}, wall_hot)
		if wall_hot:
			_add_handle(_gizmos, Vector3((f.x0 + f.x1) * 0.0005, f.height / 1000.0, (f.y0 + f.y1) * 0.0005), 0.12, HANDLE_WALL_HEIGHT, {
				"pick": HANDLE_WALL_HEIGHT, "wall_id": f.id, "height_mm": f.height,
			}, is_wall)
		for op in f.openings:
			if typeof(op) != TYPE_DICTIONARY:
				continue
			var oid := str(op.get("id", ""))
			var hot := oid == sel_op
			if not hot and not is_wall:
				continue
			var offset := float(op.get("offsetMm", 0))
			var width := float(op.get("widthMm", 0))
			var height := float(op.get("heightMm", 0))
			var sill := float(op.get("sillHeightMm", 0))
			var cy := (sill + height * 0.5) / 1000.0
			_add_handle(_gizmos, _along(f, offset + width * 0.5, cy), 0.11, HANDLE_OPENING_OFFSET, {
				"pick": HANDLE_OPENING_OFFSET,
				"wall_id": f.id,
				"opening_id": oid,
				"kind": str(op.get("kind", "door")),
				"width_mm": width,
				"height_mm": height,
				"offset_mm": offset,
				"sill_mm": sill,
			}, hot)
			_add_handle(_gizmos, _along(f, offset, cy), 0.09, HANDLE_OPENING_WIDTH, {
				"pick": HANDLE_OPENING_WIDTH,
				"edge": "left",
				"wall_id": f.id,
				"opening_id": oid,
				"kind": str(op.get("kind", "door")),
				"width_mm": width,
				"height_mm": height,
				"offset_mm": offset,
				"sill_mm": sill,
			}, hot)
			_add_handle(_gizmos, _along(f, offset + width, cy), 0.09, HANDLE_OPENING_WIDTH, {
				"pick": HANDLE_OPENING_WIDTH,
				"edge": "right",
				"wall_id": f.id,
				"opening_id": oid,
				"kind": str(op.get("kind", "door")),
				"width_mm": width,
				"height_mm": height,
				"offset_mm": offset,
				"sill_mm": sill,
			}, hot)


func _along(f: Dictionary, t_mm: float, y_m: float) -> Vector3:
	return Vector3((f.x0 + f.ux * t_mm) / 1000.0, y_m, (f.y0 + f.uy * t_mm) / 1000.0)


func _first_corner(walls: Array) -> Vector2:
	var w: Dictionary = walls[0]
	var a: Dictionary = w.get("start", {})
	return Vector2(float(a.get("x", 0)), float(a.get("y", 0)))


func _add_handle(parent: Node3D, pos: Vector3, radius: float, _kind: String, meta: Dictionary, hot: bool) -> void:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mi.mesh = mesh
	mi.material_override = _lighting.gizmo_material(hot)
	mi.position = pos
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	col.shape = shape
	body.add_child(col)
	for k in meta.keys():
		body.set_meta(str(k), meta[k])
		mi.set_meta(str(k), meta[k])
	mi.add_child(body)
	parent.add_child(mi)


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, basis: Basis, mat: Material, meta: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = Transform3D(basis, pos)
	if not meta.is_empty():
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		for k in meta.keys():
			body.set_meta(str(k), meta[k])
			mi.set_meta(str(k), meta[k])
		mi.add_child(body)
	parent.add_child(mi)


func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.free()


func _orbit() -> void:
	if _camera == null:
		return
	var offset := Vector3(
		_distance * cos(_pitch) * sin(_yaw),
		_distance * sin(-_pitch),
		_distance * cos(_pitch) * cos(_yaw)
	)
	_camera.look_at_from_position(_target + offset, _target)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = max(3.0, _distance - 0.6)
			_orbit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = min(28.0, _distance + 0.6)
			_orbit()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_left_down(mb.position)
			else:
				_on_left_up()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if not _drag.is_empty():
			_on_drag(mm.position)
			get_viewport().set_input_as_handled()
		elif _orbiting:
			_yaw -= mm.relative.x * 0.005
			_pitch = clampf(_pitch - mm.relative.y * 0.005, -1.25, -0.08)
			_orbit()
	elif event is InputEventScreenDrag and _drag.is_empty():
		var sd := event as InputEventScreenDrag
		_yaw -= sd.relative.x * 0.005
		_pitch = clampf(_pitch - sd.relative.y * 0.005, -1.25, -0.08)
		_orbit()


func _on_left_down(pos: Vector2) -> void:
	var hit := _intersect(pos, 2)
	if hit.is_empty():
		hit = _intersect(pos, 1)
	if hit.is_empty():
		_selected = {}
		_drag = {}
		_refresh_world(true)
		return
	var body: Object = hit.get("collider")
	if body == null:
		return
	var pick := str(body.get_meta("pick", ""))
	if pick == HANDLE_WALL_END or pick == HANDLE_WALL_HEIGHT or pick == HANDLE_OPENING_OFFSET or pick == HANDLE_OPENING_WIDTH or pick == HANDLE_STOREY_HEIGHT:
		_drag = _meta_dict(body)
		_drag["node"] = hit.get("collider").get_parent()
		if _drag.has("opening_id"):
			_selected = {"pick": KIND_OPENING, "opening_id": str(_drag.opening_id), "wall_id": str(_drag.get("wall_id", ""))}
		elif _drag.has("wall_id"):
			_selected = {"pick": KIND_WALL, "wall_id": str(_drag.wall_id)}
		return
	if pick == KIND_OPENING:
		_selected = {"pick": KIND_OPENING, "opening_id": str(body.get_meta("opening_id", "")), "wall_id": str(body.get_meta("wall_id", "")), "kind": str(body.get_meta("kind", ""))}
		_drag = {}
		_refresh_world(true)
	elif pick == KIND_WALL:
		_selected = {"pick": KIND_WALL, "wall_id": str(body.get_meta("wall_id", ""))}
		_drag = {}
		_refresh_world(true)
	elif pick == KIND_HOSTED:
		_selected = {"pick": KIND_HOSTED, "hosted_id": str(body.get_meta("hosted_id", "")), "wall_id": str(body.get_meta("wall_id", ""))}
		_drag = {}
		_refresh_world(true)


func _on_drag(pos: Vector2) -> void:
	if _drag.is_empty():
		return
	var ray := _ray(pos)
	var pick := str(_drag.get("pick", ""))
	var node: Node3D = _drag.get("node") as Node3D
	if pick == HANDLE_WALL_END:
		var hit := _ray_xz(ray.from, ray.dir, 0.0)
		var x_mm := _snap_mm(hit.x * 1000.0)
		var y_mm := _snap_mm(hit.z * 1000.0)
		_drag["x_mm"] = x_mm
		_drag["y_mm"] = y_mm
		if node:
			node.position = Vector3(x_mm / 1000.0, node.position.y, y_mm / 1000.0)
	elif pick == HANDLE_WALL_HEIGHT or pick == HANDLE_STOREY_HEIGHT:
		var y_m := _ray_height(ray.from, ray.dir, node.position if node else _target)
		var h_mm := _snap_mm(clampf(y_m * 1000.0, 1200.0, 6000.0))
		_drag["height_mm"] = h_mm
		if node:
			node.position.y = h_mm / 1000.0
	elif pick == HANDLE_OPENING_OFFSET or pick == HANDLE_OPENING_WIDTH:
		var f := _wall_by_id(str(_drag.get("wall_id", "")))
		if f.is_empty():
			return
		var hit := _ray_xz(ray.from, ray.dir, 0.0)
		var t_mm := _snap_mm(_project_mm(f, hit))
		t_mm = clampf(t_mm, 0.0, f.length)
		if pick == HANDLE_OPENING_OFFSET:
			var width := float(_drag.get("width_mm", 900))
			var offset := clampf(t_mm - width * 0.5, 0.0, max(f.length - width, 0.0))
			_drag["offset_mm"] = offset
			if node:
				node.position = _along(f, offset + width * 0.5, node.position.y)
		else:
			var offset0 := float(_drag.get("offset_mm", 0))
			var width0 := float(_drag.get("width_mm", 900))
			if str(_drag.get("edge", "")) == "left":
				var right := offset0 + width0
				var left := clampf(t_mm, 0.0, right - 200.0)
				_drag["offset_mm"] = left
				_drag["width_mm"] = right - left
			else:
				var left2 := offset0
				var right2 := clampf(t_mm, left2 + 200.0, f.length)
				_drag["width_mm"] = right2 - left2
			if node:
				node.position = _along(f, t_mm, node.position.y)
	_update_hud()


func _on_left_up() -> void:
	if _drag.is_empty():
		return
	_commit_drag()
	_drag = {}


func _commit_drag() -> void:
	var pick := str(_drag.get("pick", ""))
	if pick == HANDLE_WALL_END:
		if abs(float(_drag.get("orig_x_mm", 0)) - float(_drag.get("x_mm", 0))) < 0.51 and abs(float(_drag.get("orig_y_mm", 0)) - float(_drag.get("y_mm", 0))) < 0.51:
			return
		Session.move_shared_vertex(
			float(_drag.get("orig_x_mm", 0)),
			float(_drag.get("orig_y_mm", 0)),
			float(_drag.get("x_mm", 0)),
			float(_drag.get("y_mm", 0))
		)
	elif pick == HANDLE_WALL_HEIGHT:
		if abs(float(_drag.get("orig_height_mm", 0)) - float(_drag.get("height_mm", 0))) < 0.51:
			return
		Session.set_wall_height_mm(str(_drag.get("wall_id", "")), float(_drag.get("height_mm", 2800)))
	elif pick == HANDLE_STOREY_HEIGHT:
		if abs(float(_drag.get("orig_height_mm", 0)) - float(_drag.get("height_mm", 0))) < 0.51:
			return
		Session.set_storey_height(float(_drag.get("height_mm", 2800)))
	elif pick == HANDLE_OPENING_OFFSET or pick == HANDLE_OPENING_WIDTH:
		if abs(float(_drag.get("orig_offset_mm", 0)) - float(_drag.get("offset_mm", 0))) < 0.51 and abs(float(_drag.get("orig_width_mm", 0)) - float(_drag.get("width_mm", 0))) < 0.51:
			return
		Session.update_opening_geom(
			str(_drag.get("opening_id", "")),
			str(_drag.get("kind", "door")),
			float(_drag.get("width_mm", 900)),
			float(_drag.get("height_mm", 2100)),
			float(_drag.get("offset_mm", 0)),
			float(_drag.get("sill_mm", 0))
		)


func _meta_dict(body: Object) -> Dictionary:
	var d := {}
	for k in ["pick", "wall_id", "opening_id", "hosted_id", "kind", "end", "edge"]:
		if body.has_meta(k):
			d[k] = body.get_meta(k)
	for k in ["x_mm", "y_mm", "width_mm", "height_mm", "offset_mm", "sill_mm"]:
		if body.has_meta(k):
			d[k] = float(body.get_meta(k))
	if d.has("x_mm"):
		d["orig_x_mm"] = float(d.x_mm)
	if d.has("y_mm"):
		d["orig_y_mm"] = float(d.y_mm)
	if d.has("offset_mm"):
		d["orig_offset_mm"] = float(d.offset_mm)
	if d.has("width_mm"):
		d["orig_width_mm"] = float(d.width_mm)
	if d.has("height_mm"):
		d["orig_height_mm"] = float(d.height_mm)
	return d


func _wall_by_id(wall_id: String) -> Dictionary:
	for w in _walls():
		if typeof(w) == TYPE_DICTIONARY and str(w.get("id", "")) == wall_id:
			return _frame(w)
	return {}


func _project_mm(f: Dictionary, hit: Vector3) -> float:
	var a := Vector3(f.x0 / 1000.0, 0.0, f.y0 / 1000.0)
	var dir := Vector3(f.ux, 0.0, f.uy)
	return (hit - a).dot(dir) * 1000.0


func _snap_mm(v: float) -> float:
	return round(v / 10.0) * 10.0


func _ray(pos: Vector2) -> Dictionary:
	return {"from": _camera.project_ray_origin(pos), "dir": _camera.project_ray_normal(pos)}


func _ray_xz(from: Vector3, dir: Vector3, y: float) -> Vector3:
	if abs(dir.y) < 0.0001:
		return Vector3(from.x, y, from.z)
	var t := (y - from.y) / dir.y
	return from + dir * t


func _ray_height(from: Vector3, dir: Vector3, at: Vector3) -> float:
	var d := Vector2(dir.x, dir.z)
	var f := Vector2(from.x - at.x, from.z - at.z)
	var denom := d.length_squared()
	if denom < 0.0001:
		return from.y
	var s := -f.dot(d) / denom
	return from.y + s * dir.y


func _intersect(pos: Vector2, mask: int) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var ray := _ray(pos)
	var q := PhysicsRayQueryParameters3D.create(ray.from, ray.from + ray.dir * 80.0)
	q.collision_mask = mask
	q.collide_with_areas = false
	q.collide_with_bodies = true
	return space.intersect_ray(q)


func _update_hud() -> void:
	var walls: Array = _walls()
	var light := _lighting.preset_label() if _lighting else "—"
	var gate := Session.last_rebuild
	var gate_s := str(gate.get("status", "—"))
	if Session.keep_preview:
		_status.text = "3D 编辑 · 灯光 %s · StatusGate Fault — 预览保持上一版实体\n%s" % [light, Session.last_error]
	elif walls.is_empty():
		_status.text = "3D 编辑 · 灯光 %s\n尚无墙。请返回户型图画墙，或加载夹具样例。" % light
	else:
		_status.text = "3D 编辑 · 灯光 %s · StatusGate %s · 网格非尺寸真相" % [light, gate_s]
	var sel := "未选择。点墙/门洞/窗洞/垭口，拖动手柄。"
	var pick := str(_selected.get("pick", ""))
	if pick == KIND_OPENING:
		var op := _opening_by_id(str(_selected.get("opening_id", "")))
		var kind := str(op.get("kind", _selected.get("kind", "")))
		var label := {"door": "门洞", "window": "窗洞", "archway": "垭口"}.get(kind, kind)
		sel = "选中 %s %s  偏移 %dmm  宽 %dmm  高 %dmm" % [
			label,
			str(_selected.get("opening_id", "")),
			int(float(op.get("offsetMm", _drag.get("offset_mm", 0)))),
			int(float(op.get("widthMm", _drag.get("width_mm", 0)))),
			int(float(op.get("heightMm", 0))),
		]
	elif pick == KIND_WALL:
		sel = "选中墙 %s（拖两端点 / 顶面层高手柄）" % str(_selected.get("wall_id", ""))
	elif pick == KIND_HOSTED:
		sel = "选中宿主构件 %s（命令编辑；非三角网）" % str(_selected.get("hosted_id", ""))
	if not _drag.is_empty():
		sel += "  · 拖动中，松开后经 C API 提交"
	_sel_label.text = sel


func _opening_by_id(oid: String) -> Dictionary:
	for w in _walls():
		if typeof(w) != TYPE_DICTIONARY:
			continue
		for op in w.get("openings", []):
			if typeof(op) == TYPE_DICTIONARY and str(op.get("id", "")) == oid:
				return op
	return {}
