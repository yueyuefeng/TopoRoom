extends Control
## 自由绘制 — tap-drag walls into SceneIR, then 完成 → 2D editor.

const NumericSheet := preload("res://app/ui/numeric_sheet.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")
const JoyplanChrome := preload("res://app/joyplan_flow/joyplan_chrome.gd")

const MM_PER_PX := 8.0
const PAD := 56.0
const SNAP_PX := 28.0
const HANDLE_R := 16.0
const HANDLE_HIT := 36.0
const WALL_HIT := 20.0
const MIN_MM := 200.0
const AXIS_RATIO := 2.4

var _canvas: Control
var _numeric: Control
var _snack: PanelContainer
var _hint: Label
var _selected := ""
var _drag := 0  # 0 none, 1 draw, 2 handle-a, 3 handle-b
var _draw_a := Vector2.ZERO
var _draw_b := Vector2.ZERO
var _pending_id := ""
var _handle_orig := PackedVector2Array()


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_FREE_DRAW
	if not Session.from_free_draw:
		Session.start_free_draw(true)

	var bg := ColorRect.new()
	bg.color = Color("F4F4F4")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_canvas = Control.new()
	_canvas.name = "DrawCanvas"
	_canvas.set_anchors_preset(PRESET_FULL_RECT)
	_canvas.offset_top = 56
	_canvas.offset_bottom = -80
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.gui_input.connect(_on_canvas_input)
	_canvas.draw.connect(_draw_canvas)
	add_child(_canvas)

	add_child(JoyplanChrome.step_bar(
		"自由绘制",
		"完成",
		func(): FlowRouter.new_plan(self),
		func(): _finish()
	))

	_hint = Studio.label("拖动画墙 · 对齐轴线与端点", Tokens.FONT_CAPTION, Tokens.TEXT_SECONDARY)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(PRESET_TOP_WIDE)
	_hint.offset_top = 64
	_hint.offset_bottom = 88
	add_child(_hint)

	_build_dock()

	_numeric = NumericSheet.new()
	_numeric.committed.connect(_on_numeric)
	add_child(_numeric)

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -148
	_snack.offset_bottom = -98
	add_child(_snack)
	Session.document_changed.connect(_queue_draw)


func _build_dock() -> void:
	var dock := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	dock.add_theme_stylebox_override("panel", sb)
	dock.set_anchors_preset(PRESET_BOTTOM_WIDE)
	dock.anchor_top = 1.0
	dock.offset_top = -80
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_dock_btn("↶ 撤销", func(): _undo()))
	row.add_child(_dock_btn("清除上一段", func(): _clear_last()))
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)
	row.add_child(_dock_btn("删除", func(): _delete_selected(), Tokens.DANGER))
	var done := Button.new()
	done.text = "完成"
	done.focus_mode = Control.FOCUS_NONE
	done.custom_minimum_size = Vector2(88, 44)
	done.add_theme_font_override("font", Studio.font)
	done.add_theme_font_size_override("font_size", 16)
	done.add_theme_color_override("font_color", Tokens.JP_ORANGE)
	done.add_theme_color_override("font_hover_color", Tokens.JP_ORANGE)
	var empty := StyleBoxEmpty.new()
	done.add_theme_stylebox_override("normal", empty)
	done.add_theme_stylebox_override("hover", empty)
	done.add_theme_stylebox_override("pressed", empty)
	done.pressed.connect(_finish)
	row.add_child(done)
	dock.add_child(row)
	add_child(dock)


func _dock_btn(text: String, cb: Callable, ink: Color = Tokens.TEXT) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", ink)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("F3F3F3")
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(cb)
	return b


func _queue_draw() -> void:
	if _canvas:
		_canvas.queue_redraw()


func _walls() -> Array:
	var parsed: Variant = JSON.parse_string(Session.sceneir_json())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var storeys: Array = parsed.get("storeys", [])
	if storeys.is_empty() or typeof(storeys[0]) != TYPE_DICTIONARY:
		return []
	return storeys[0].get("walls", [])


func _to_px(mm: Vector2) -> Vector2:
	return Vector2(PAD + mm.x / MM_PER_PX, _canvas.size.y - PAD - mm.y / MM_PER_PX)


func _to_mm(p: Vector2) -> Vector2:
	return Vector2((p.x - PAD) * MM_PER_PX, (_canvas.size.y - PAD - p.y) * MM_PER_PX)


func _endpoints() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for w in _walls():
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		out.append(Vector2(float(a.get("x", 0)), float(a.get("y", 0))))
		out.append(Vector2(float(b.get("x", 0)), float(b.get("y", 0))))
	return out


func _snap_mm(mm: Vector2, skip: Vector2 = Vector2.INF) -> Vector2:
	var best := mm
	var best_d := SNAP_PX * MM_PER_PX
	for p in _endpoints():
		if skip != Vector2.INF and p.distance_to(skip) < 0.5:
			continue
		var d: float = p.distance_to(mm)
		if d < best_d:
			best_d = d
			best = p
	return best


func _axis_snap(a: Vector2, b: Vector2) -> Vector2:
	var d: Vector2 = b - a
	if absf(d.x) >= absf(d.y) * AXIS_RATIO:
		return Vector2(b.x, a.y)
	if absf(d.y) >= absf(d.x) * AXIS_RATIO:
		return Vector2(a.x, b.y)
	return b


func _event_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return (event as InputEventMouse).position
	if event is InputEventScreenTouch:
		return _canvas.get_global_transform_with_canvas().affine_inverse() * (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return _canvas.get_global_transform_with_canvas().affine_inverse() * (event as InputEventScreenDrag).position
	return Vector2.INF


func _on_canvas_input(event: InputEvent) -> void:
	var pos := _event_pos(event)
	if not is_finite(pos.x):
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_begin(pos)
		else:
			_end(pos)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_begin(pos)
		else:
			_end(pos)
		get_viewport().set_input_as_handled()
		return
	if _drag == 0:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_move(pos)
		get_viewport().set_input_as_handled()


func _begin(pos: Vector2) -> void:
	var hit := _hit_handle(pos)
	if not hit.is_empty():
		_selected = str(hit.get("id", ""))
		_drag = int(hit.get("end", 2))
		_pending_id = _selected
		var w: Dictionary = Session.find_wall(_selected)
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		_handle_orig = PackedVector2Array([
			Vector2(float(a.get("x", 0)), float(a.get("y", 0))),
			Vector2(float(b.get("x", 0)), float(b.get("y", 0))),
		])
		_queue_draw()
		return
	if _hit_label(pos):
		_edit_length()
		return
	var wid := _hit_wall(pos)
	if not wid.is_empty():
		_selected = wid
		_drag = 0
		_queue_draw()
		return
	_selected = ""
	_drag = 1
	var start_mm := _snap_mm(_to_mm(pos))
	_draw_a = start_mm
	_draw_b = start_mm
	_queue_draw()


func _move(pos: Vector2) -> void:
	if _drag == 1:
		var raw := _to_mm(pos)
		_draw_b = _snap_mm(_axis_snap(_draw_a, raw), _draw_a)
		_queue_draw()
		return
	if _drag == 2 or _drag == 3:
		var w: Dictionary = Session.find_wall(_selected)
		if w.is_empty():
			return
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		var p0 := Vector2(float(a.get("x", 0)), float(a.get("y", 0)))
		var p1 := Vector2(float(b.get("x", 0)), float(b.get("y", 0)))
		var raw := _to_mm(pos)
		if _drag == 2:
			p0 = _snap_mm(_axis_snap(p1, raw), p1)
		else:
			p1 = _snap_mm(_axis_snap(p0, raw), p0)
		if p0.distance_to(p1) >= MIN_MM:
			Session.move_drawn_wall(_selected, p0.x, p0.y, p1.x, p1.y, false)
		_queue_draw()


func _end(pos: Vector2) -> void:
	if _drag == 1:
		var raw := _to_mm(pos)
		_draw_b = _snap_mm(_axis_snap(_draw_a, raw), _draw_a)
		if _draw_a.distance_to(_draw_b) >= MIN_MM:
			var err := Session.add_drawn_wall(_draw_a.x, _draw_a.y, _draw_b.x, _draw_b.y)
			if err == "":
				_selected = "wall_d%d" % Session.wall_serial
		_drag = 0
		_draw_a = Vector2.ZERO
		_draw_b = Vector2.ZERO
		_queue_draw()
		return
	if _drag == 2 or _drag == 3:
		if _handle_orig.size() == 2:
			var cur: Dictionary = Session.find_wall(_selected)
			if cur.is_empty():
				_handle_orig = PackedVector2Array()
				_drag = 0
				_queue_draw()
				return
			var a: Dictionary = cur.get("start", {})
			var b: Dictionary = cur.get("end", {})
			var now0 := Vector2(float(a.get("x", 0)), float(a.get("y", 0)))
			var now1 := Vector2(float(b.get("x", 0)), float(b.get("y", 0)))
			if now0.distance_to(_handle_orig[0]) > 0.5 or now1.distance_to(_handle_orig[1]) > 0.5:
				Session.draw_undo.append({
					"op": "move", "id": _selected,
					"x0": _handle_orig[0].x, "y0": _handle_orig[0].y,
					"x1": _handle_orig[1].x, "y1": _handle_orig[1].y,
				})
		_handle_orig = PackedVector2Array()
	_drag = 0
	_queue_draw()


func _hit_handle(pos: Vector2) -> Dictionary:
	if _selected.is_empty():
		return {}
	var w: Dictionary = Session.find_wall(_selected)
	if w.is_empty():
		return {}
	var a: Dictionary = w.get("start", {})
	var b: Dictionary = w.get("end", {})
	var pa := _to_px(Vector2(float(a.get("x", 0)), float(a.get("y", 0))))
	var pb := _to_px(Vector2(float(b.get("x", 0)), float(b.get("y", 0))))
	if pa.distance_to(pos) <= HANDLE_HIT:
		return {"id": _selected, "end": 2}
	if pb.distance_to(pos) <= HANDLE_HIT:
		return {"id": _selected, "end": 3}
	return {}


func _hit_wall(pos: Vector2) -> String:
	var best := ""
	var best_d := WALL_HIT
	for w in _walls():
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		var pa := _to_px(Vector2(float(a.get("x", 0)), float(a.get("y", 0))))
		var pb := _to_px(Vector2(float(b.get("x", 0)), float(b.get("y", 0))))
		var d := _dist_seg(pos, pa, pb)
		if d < best_d:
			best_d = d
			best = str(w.get("id", ""))
	return best


func _hit_label(pos: Vector2) -> bool:
	if _selected.is_empty():
		return false
	var mid := _label_pos(_selected)
	return mid.distance_to(pos) <= 28.0


func _label_pos(wall_id: String) -> Vector2:
	var w: Dictionary = Session.find_wall(wall_id)
	if w.is_empty():
		return Vector2.INF
	var a: Dictionary = w.get("start", {})
	var b: Dictionary = w.get("end", {})
	var pa := _to_px(Vector2(float(a.get("x", 0)), float(a.get("y", 0))))
	var pb := _to_px(Vector2(float(b.get("x", 0)), float(b.get("y", 0))))
	return pa.lerp(pb, 0.5) + Vector2(0, -18)


func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom := ab.length_squared()
	if denom < 1.0:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _draw_canvas() -> void:
	if _canvas == null:
		return
	_draw_paper()
	for w in _walls():
		if typeof(w) != TYPE_DICTIONARY:
			continue
		_stroke_wall(w, str(w.get("id", "")) == _selected)
	if _drag == 1 and _draw_a.distance_to(_draw_b) >= 8.0:
		var pa := _to_px(_draw_a)
		var pb := _to_px(_draw_b)
		_canvas.draw_line(pa, pb, Color(0.12, 0.45, 0.98, 0.95), 5.0)
		_canvas.draw_circle(pa, 6.0, Color(0.12, 0.45, 0.98, 1))
		_canvas.draw_circle(pb, 6.0, Color(0.12, 0.45, 0.98, 1))
		_draw_len(pa, pb, _draw_a.distance_to(_draw_b), Color(0.12, 0.45, 0.98, 1))


func _draw_paper() -> void:
	_canvas.draw_rect(Rect2(Vector2.ZERO, _canvas.size), Color("F7F7F7"))
	var step := 1000.0 / MM_PER_PX
	var x := PAD
	while x < _canvas.size.x:
		_canvas.draw_line(Vector2(x, 0), Vector2(x, _canvas.size.y), Color(0.86, 0.86, 0.88, 1), 1.0)
		x += step
	var y := _canvas.size.y - PAD
	while y > 0.0:
		_canvas.draw_line(Vector2(0, y), Vector2(_canvas.size.x, y), Color(0.86, 0.86, 0.88, 1), 1.0)
		y -= step
	_canvas.draw_rect(Rect2(Vector2(8, 8), _canvas.size - Vector2(16, 16)), Color(0.82, 0.82, 0.84, 1), false, 1.0)


func _stroke_wall(w: Dictionary, selected: bool) -> void:
	var a: Dictionary = w.get("start", {})
	var b: Dictionary = w.get("end", {})
	var pa := _to_px(Vector2(float(a.get("x", 0)), float(a.get("y", 0))))
	var pb := _to_px(Vector2(float(b.get("x", 0)), float(b.get("y", 0))))
	var length := Vector2(float(b.get("x", 0)) - float(a.get("x", 0)), float(b.get("y", 0)) - float(a.get("y", 0))).length()
	var ink := Tokens.PAGE_SELECT if selected else Tokens.WALL_JOY
	_canvas.draw_line(pa, pb, ink, 10.0 if selected else 8.0)
	_draw_len(pa, pb, length, ink)
	if selected:
		_canvas.draw_circle(pa, HANDLE_R, Color.WHITE)
		_canvas.draw_circle(pa, HANDLE_R - 3.0, Color(0.22, 0.55, 1.0, 1))
		_canvas.draw_circle(pb, HANDLE_R, Color.WHITE)
		_canvas.draw_circle(pb, HANDLE_R - 3.0, Color(0.22, 0.55, 1.0, 1))


func _draw_len(pa: Vector2, pb: Vector2, length_mm: float, ink: Color) -> void:
	var mid: Vector2 = pa.lerp(pb, 0.5) + Vector2(0, -16)
	var txt := "%d mm" % int(round(length_mm))
	var f := Studio.font if Studio and Studio.font else ThemeDB.fallback_font
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_canvas.draw_rect(Rect2(mid + Vector2(-tw * 0.5 - 6, -12), Vector2(tw + 12, 20)), Color(1, 1, 1, 0.92), true)
	_canvas.draw_string(f, mid + Vector2(-tw * 0.5, 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)


func _edit_length() -> void:
	if _selected.is_empty():
		return
	var m: Dictionary = Session.find_wall(_selected)
	if m.is_empty():
		return
	_pending_id = _selected
	_numeric.present("墙长 mm", float(m.get("length_mm", 0)), 200.0, 20000.0)


func _on_numeric(value_mm: float) -> void:
	if _pending_id.is_empty():
		return
	Session.resize_wall_length(_pending_id, value_mm)
	_queue_draw()


func _undo() -> void:
	var err := Session.undo_draw()
	if err != "" and _snack:
		_snack.show_message(err)
	if Session.find_wall(_selected).is_empty():
		_selected = ""
	_queue_draw()


func _clear_last() -> void:
	var err := Session.clear_last_drawn()
	if err != "" and _snack:
		_snack.show_message(err)
	if Session.find_wall(_selected).is_empty():
		_selected = ""
	_queue_draw()


func _delete_selected() -> void:
	if _selected.is_empty():
		if _snack:
			_snack.show_message("先点选一道墙")
		return
	Session.delete_drawn_wall(_selected)
	_selected = ""
	_queue_draw()


func _finish() -> void:
	if Session.drawn_wall_count() <= 0:
		if _snack:
			_snack.show_message("先画至少一道墙")
		return
	Session.from_free_draw = true
	FlowRouter.edit_2d(self)


## Headless / capture helpers.
func draw_segment_mm(x0: float, y0: float, x1: float, y1: float) -> String:
	return Session.add_drawn_wall(x0, y0, x1, y1)


func draw_rectangle_mm(width_mm: float = 4000.0, depth_mm: float = 3000.0) -> String:
	var err := Session.add_drawn_wall(0, 0, width_mm, 0)
	if err != "":
		return err
	err = Session.add_drawn_wall(width_mm, 0, width_mm, depth_mm)
	if err != "":
		return err
	err = Session.add_drawn_wall(width_mm, depth_mm, 0, depth_mm)
	if err != "":
		return err
	return Session.add_drawn_wall(0, depth_mm, 0, 0)
