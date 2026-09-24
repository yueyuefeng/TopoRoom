extends Control
## AR扫描 — camera-guided wall capture → SceneIR add_wall, then 完成 → 2D.
## ARCore plane hit-test when the plugin reports it; otherwise guided measure
## + 演示房间. No LiDAR accessory required.

const NumericSheet := preload("res://app/ui/numeric_sheet.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")
const JoyplanChrome := preload("res://app/joyplan_flow/joyplan_chrome.gd")

const PLUGIN_NAME := "TopoRoomMedia"
const MIN_MM := 200.0
const CLOSE_MM := 400.0
const DEFAULT_LEN := 3000.0

var _finder: Control
var _preview: TextureRect
var _overlay: Control
var _hint: Label
var _chip: Label
var _len_btn: Button
var _turn_lab: Label
var _snack: PanelContainer
var _numeric: Control
var _mode := "guide"  # ar | guide
var _points: PackedVector2Array = PackedVector2Array()
var _origin_world := Vector3.ZERO
var _has_origin := false
var _heading := 0.0
var _next_len := DEFAULT_LEN
var _plugin: Object
var _camera_on := false


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_AR_SCAN
	if not Session.from_ar_scan:
		Session.start_ar_scan(true)

	_preview = TextureRect.new()
	_preview.name = "CameraPreview"
	_preview.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_preview)

	_finder = Control.new()
	_finder.name = "Finder"
	_finder.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_finder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finder.draw.connect(_draw_finder)
	add_child(_finder)

	_overlay = Control.new()
	_overlay.name = "PlanOverlay"
	_overlay.set_anchors_preset(PRESET_BOTTOM_LEFT)
	_overlay.anchor_top = 1.0
	_overlay.anchor_right = 0.0
	_overlay.offset_left = 16
	_overlay.offset_top = -280
	_overlay.offset_right = 196
	_overlay.offset_bottom = -140
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)

	add_child(JoyplanChrome.step_bar(
		"AR扫描",
		"完成",
		func(): FlowRouter.new_plan(self),
		func(): _finish()
	))

	_chip = Studio.label("引导量墙", Tokens.FONT_CHIP, Color.WHITE)
	_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip.set_anchors_preset(PRESET_CENTER_TOP)
	_chip.anchor_left = 0.5
	_chip.anchor_right = 0.5
	_chip.offset_left = -92
	_chip.offset_right = 92
	_chip.offset_top = 68
	_chip.offset_bottom = 94
	add_child(_chip)

	_hint = Studio.label("对准墙角，点「标记墙角」", Tokens.FONT_CAPTION, Color(1, 1, 1, 0.92))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_preset(PRESET_TOP_WIDE)
	_hint.offset_top = 100
	_hint.offset_bottom = 124
	add_child(_hint)

	_len_btn = Button.new()
	_len_btn.text = "下一墙  3000 mm"
	_len_btn.focus_mode = Control.FOCUS_NONE
	_len_btn.set_anchors_preset(PRESET_CENTER_TOP)
	_len_btn.anchor_left = 0.5
	_len_btn.anchor_right = 0.5
	_len_btn.offset_left = -110
	_len_btn.offset_right = 110
	_len_btn.offset_top = 132
	_len_btn.offset_bottom = 168
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color(0.08, 0.09, 0.12, 0.72)
	lsb.set_corner_radius_all(14)
	_len_btn.add_theme_stylebox_override("normal", lsb)
	_len_btn.add_theme_stylebox_override("hover", lsb)
	_len_btn.add_theme_stylebox_override("pressed", lsb)
	_len_btn.add_theme_font_override("font", Studio.font)
	_len_btn.add_theme_font_size_override("font_size", 14)
	_len_btn.add_theme_color_override("font_color", Color.WHITE)
	_len_btn.pressed.connect(_edit_len)
	add_child(_len_btn)

	_turn_lab = Studio.label("下一转向  右转 90°", Tokens.FONT_CAPTION, Color(1, 1, 1, 0.8))
	_turn_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_lab.set_anchors_preset(PRESET_TOP_WIDE)
	_turn_lab.offset_top = 172
	_turn_lab.offset_bottom = 192
	add_child(_turn_lab)

	_build_dock()

	_numeric = NumericSheet.new()
	_numeric.committed.connect(_on_numeric)
	add_child(_numeric)

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -168
	_snack.offset_bottom = -118
	add_child(_snack)

	Session.document_changed.connect(_redraw)
	_probe_backend()
	_refresh_chrome()


func _build_dock() -> void:
	var dock := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.10, 0.92)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	dock.add_theme_stylebox_override("panel", sb)
	dock.set_anchors_preset(PRESET_BOTTOM_WIDE)
	dock.anchor_top = 1.0
	dock.offset_top = -132
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_dock_btn("↶ 撤销", func(): _undo(), Color(0.92, 0.93, 0.95)))
	row.add_child(_dock_btn("演示房间", func(): _demo_room(), Color(0.85, 0.90, 1.0)))
	row.add_child(_dock_btn("左转", func(): _turn(1), Color(0.92, 0.93, 0.95)))
	row.add_child(_dock_btn("右转", func(): _turn(-1), Color(0.92, 0.93, 0.95)))
	col.add_child(row)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.add_child(_dock_btn("标记墙角", func(): _mark(), Tokens.JP_ORANGE))
	row2.add_child(_dock_btn("闭合轮廓", func(): _close_loop(), Color(0.55, 0.92, 0.62)))
	var done := Button.new()
	done.text = "完成"
	done.focus_mode = Control.FOCUS_NONE
	done.custom_minimum_size = Vector2(88, 40)
	done.add_theme_font_override("font", Studio.font)
	done.add_theme_font_size_override("font_size", 16)
	done.add_theme_color_override("font_color", Tokens.JP_ORANGE)
	var empty := StyleBoxEmpty.new()
	done.add_theme_stylebox_override("normal", empty)
	done.add_theme_stylebox_override("hover", empty)
	done.add_theme_stylebox_override("pressed", empty)
	done.pressed.connect(_finish)
	row2.add_child(done)
	col.add_child(row2)
	dock.add_child(col)
	add_child(dock)


func _dock_btn(text: String, cb: Callable, ink: Color = Color.WHITE) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 36)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", ink)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.19, 0.22, 0.95)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(cb)
	return b


func _probe_backend() -> void:
	if Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)
	var ar_state := "missing"
	if _plugin and _plugin.has_method("ar_available"):
		ar_state = str(_plugin.ar_available())
	if ar_state == "ok" and _plugin.has_method("ar_start"):
		var started := str(_plugin.ar_start())
		if started == "ok" or started.begins_with("ok"):
			_mode = "ar"
			_toast("已开启平面检测，对准墙角点标记")
			_refresh_chrome()
			return
		_toast("平面检测未能启动，改用引导量墙")
	elif ar_state == "install":
		_toast("可安装 ARCore 以量真实尺寸 · 现用引导量墙")
	elif ar_state == "unsupported" or ar_state == "missing_sdk" or ar_state == "missing":
		_toast("当前环境没有平面检测，改用引导量墙 · 可点演示房间")
	else:
		_toast("平面检测不可用（%s），改用引导量墙" % ar_state)
	_mode = "guide"
	_try_live_camera()
	_refresh_chrome()


func _try_live_camera() -> void:
	if OS.get_name() == "Android":
		OS.request_permission("android.permission.CAMERA")
	if not ClassDB.class_exists("CameraServer"):
		return
	if CameraServer.get_feed_count() <= 0:
		return
	var feed: CameraFeed = CameraServer.get_feed(0)
	if feed == null:
		return
	feed.feed_is_active = true
	var tex := CameraTexture.new()
	tex.camera_feed_id = feed.get_id()
	_preview.texture = tex
	_camera_on = true


func _refresh_chrome() -> void:
	if _chip:
		_chip.text = "平面检测" if _mode == "ar" else "引导量墙"
	if _len_btn:
		_len_btn.visible = _mode == "guide"
		_len_btn.text = "下一墙  %d mm" % int(round(_next_len))
	if _turn_lab:
		_turn_lab.visible = _mode == "guide"
	if _hint:
		if _mode == "ar":
			_hint.text = "将准星对准墙与地面交线，点标记"
		elif _points.is_empty():
			_hint.text = "从墙角开始 · 沿墙走到下一角再标记"
		else:
			_hint.text = "已标记 %d 个墙角 · 走到下一角或闭合" % _points.size()
	_redraw()


func _toast(text: String) -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.position.y < size.y - 140.0 and mb.position.y > 56.0:
			_mark()
			accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and st.position.y < size.y - 140.0 and st.position.y > 56.0:
			_mark()
			accept_event()


func _mark() -> void:
	if _mode == "ar":
		_mark_ar()
	else:
		_mark_guide()


func _mark_ar() -> void:
	if _plugin == null or not _plugin.has_method("ar_hit_center"):
		_mode = "guide"
		_toast("平面检测已断开，改用引导量墙")
		_refresh_chrome()
		_mark_guide()
		return
	var raw := str(_plugin.ar_hit_center())
	if not raw.begins_with("ok"):
		if raw == "miss" or raw == "no_plane":
			_toast("未点到地面，再对准墙角试试")
		else:
			_toast("命中失败，改用引导量墙")
			_mode = "guide"
			_refresh_chrome()
		return
	var bits := raw.split(",")
	if bits.size() < 3:
		_toast("命中数据不完整")
		return
	var wx := float(bits[1])
	var wz := float(bits[2])
	if not _has_origin:
		_origin_world = Vector3(wx, 0, wz)
		_has_origin = true
	var mm := Vector2((wx - _origin_world.x) * 1000.0, (wz - _origin_world.z) * 1000.0)
	_append_point(mm)


func _mark_guide() -> void:
	if _points.is_empty():
		_append_point(Vector2.ZERO)
		return
	var last: Vector2 = _points[_points.size() - 1]
	var nxt := last + Vector2(cos(_heading), sin(_heading)) * _next_len
	_append_point(nxt)
	_heading = wrapf(_heading - PI * 0.5, -PI, PI)
	_refresh_chrome()


func _append_point(mm: Vector2) -> void:
	if _points.size() >= 1:
		var last: Vector2 = _points[_points.size() - 1]
		if last.distance_to(mm) < MIN_MM:
			_toast("离上一墙角太近")
			return
	_points.append(mm)
	if _points.size() >= 2:
		var a: Vector2 = _points[_points.size() - 2]
		var b: Vector2 = _points[_points.size() - 1]
		var err := Session.add_ar_wall(a.x, a.y, b.x, b.y)
		if err != "" and _snack:
			_snack.show_message(err)
	if _points.size() >= 3 and _points[_points.size() - 1].distance_to(_points[0]) < CLOSE_MM:
		_toast("已接近起点，可点闭合")
	_refresh_chrome()


func _close_loop() -> void:
	if _points.size() < 3:
		_toast("至少三个墙角才能闭合")
		return
	var last: Vector2 = _points[_points.size() - 1]
	var first: Vector2 = _points[0]
	if last.distance_to(first) < MIN_MM:
		_toast("轮廓已闭合")
		return
	var err := Session.add_ar_wall(last.x, last.y, first.x, first.y)
	if err != "":
		_toast(err)
		return
	_points.append(first)
	_toast("轮廓已闭合")
	_refresh_chrome()


func _turn(sign: int) -> void:
	_heading = wrapf(_heading + sign * PI * 0.5, -PI, PI)
	_refresh_chrome()
	if _turn_lab:
		_turn_lab.text = "下一转向  %s 90°" % ("左转" if sign > 0 else "右转")


func _edit_len() -> void:
	_numeric.present("下一墙长 mm", _next_len, 400.0, 20000.0)


func _on_numeric(value_mm: float) -> void:
	_next_len = maxf(value_mm, MIN_MM)
	_refresh_chrome()


func _undo() -> void:
	if Session.drawn_wall_count() > 0:
		var err := Session.undo_draw()
		if err != "" and _snack:
			_snack.show_message(err)
	if _points.size() > 0:
		_points.remove_at(_points.size() - 1)
	if _points.is_empty():
		_has_origin = false
	_refresh_chrome()


func _demo_room() -> void:
	Session.start_ar_scan(true)
	_points = PackedVector2Array()
	_has_origin = false
	_heading = 0.0
	var err := Session.ar_demo_rectangle(4000.0, 3000.0)
	if err != "":
		_toast(err)
		return
	_points = PackedVector2Array([
		Vector2(0, 0), Vector2(4000, 0), Vector2(4000, 3000), Vector2(0, 3000), Vector2(0, 0)
	])
	_toast("已写入演示房间 4000×3000")
	_refresh_chrome()


func _finish() -> void:
	if Session.drawn_wall_count() <= 0:
		if _points.size() >= 3:
			var err := Session.commit_ar_polyline(_points, true)
			if err != "":
				_toast(err)
				return
		else:
			_toast("先标记墙角，或点演示房间")
			return
	elif _points.size() >= 3:
		var last: Vector2 = _points[_points.size() - 1]
		if last.distance_to(_points[0]) >= MIN_MM:
			Session.add_ar_wall(last.x, last.y, _points[0].x, _points[0].y)
	_stop_ar()
	Session.from_ar_scan = true
	FlowRouter.edit_2d(self)


func _stop_ar() -> void:
	if _plugin and _plugin.has_method("ar_stop"):
		_plugin.ar_stop()


func _exit_tree() -> void:
	_stop_ar()


func _redraw() -> void:
	if _finder:
		_finder.queue_redraw()
	if _overlay:
		_overlay.queue_redraw()


func _draw_finder() -> void:
	if _finder == null:
		return
	var r := Rect2(Vector2.ZERO, _finder.size)
	if not _camera_on:
		_finder.draw_rect(r, Color(0.07, 0.09, 0.12, 1))
		_draw_perspective(r)
	else:
		_finder.draw_rect(r, Color(0.02, 0.03, 0.04, 0.18))
	var cx := r.size.x * 0.5
	var cy := r.size.y * 0.42
	var ink := Color(0.95, 0.96, 0.98, 0.92)
	_finder.draw_line(Vector2(cx - 28, cy), Vector2(cx + 28, cy), ink, 2.0)
	_finder.draw_line(Vector2(cx, cy - 28), Vector2(cx, cy + 28), ink, 2.0)
	_finder.draw_arc(Vector2(cx, cy), 18, 0, TAU, 32, ink, 1.5)
	var m := 22.0
	var L := 28.0
	var bracket := Color(1, 1, 1, 0.55)
	for corner in [Vector2(m, 64), Vector2(r.size.x - m, 64), Vector2(m, r.size.y - 100), Vector2(r.size.x - m, r.size.y - 100)]:
		var sx := 1.0 if corner.x < r.size.x * 0.5 else -1.0
		var sy := 1.0 if corner.y < r.size.y * 0.5 else -1.0
		_finder.draw_line(corner, corner + Vector2(sx * L, 0), bracket, 2.0)
		_finder.draw_line(corner, corner + Vector2(0, sy * L), bracket, 2.0)


func _draw_perspective(r: Rect2) -> void:
	var horizon := r.size.y * 0.38
	_finder.draw_rect(Rect2(0, 0, r.size.x, horizon), Color(0.16, 0.22, 0.28, 1))
	_finder.draw_rect(Rect2(0, horizon, r.size.x, r.size.y - horizon), Color(0.10, 0.11, 0.13, 1))
	var vanish := Vector2(r.size.x * 0.5, horizon)
	var grid := Color(0.55, 0.72, 0.78, 0.22)
	for i in range(-6, 7):
		var foot := Vector2(r.size.x * 0.5 + i * 90.0, r.size.y)
		_finder.draw_line(vanish, foot, grid, 1.0)
	var y := horizon + 16
	while y < r.size.y:
		_finder.draw_line(Vector2(0, y), Vector2(r.size.x, y), grid, 1.0)
		y += 28 + (y - horizon) * 0.12


func _draw_overlay() -> void:
	if _overlay == null:
		return
	var r := Rect2(Vector2.ZERO, _overlay.size)
	_overlay.draw_rect(r, Color(0.06, 0.07, 0.09, 0.82), true)
	_overlay.draw_rect(r, Color(1, 1, 1, 0.16), false, 1.0)
	var pts := _overlay_points()
	if pts.size() < 1:
		var f := Studio.font if Studio and Studio.font else ThemeDB.fallback_font
		_overlay.draw_string(f, Vector2(12, 28), "轮廓", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.55))
		return
	var ink := Color(0.45, 0.82, 1.0, 0.95)
	for i in range(pts.size() - 1):
		_overlay.draw_line(pts[i], pts[i + 1], ink, 3.0)
	for p in pts:
		_overlay.draw_circle(p, 4.0, Color.WHITE)
	if pts.size() >= 3:
		_overlay.draw_line(pts[pts.size() - 1], pts[0], Color(0.45, 0.92, 0.55, 0.55), 1.5)


func _overlay_points() -> PackedVector2Array:
	var src := _points
	if src.is_empty():
		src = _walls_as_points()
	if src.is_empty():
		return PackedVector2Array()
	var min_p := src[0]
	var max_p := src[0]
	for p in src:
		min_p = Vector2(minf(min_p.x, p.x), minf(min_p.y, p.y))
		max_p = Vector2(maxf(max_p.x, p.x), maxf(max_p.y, p.y))
	var span := max_p - min_p
	var box := _overlay.size - Vector2(20, 20)
	var scale := 1.0
	if span.x > 1.0 or span.y > 1.0:
		scale = minf(box.x / maxf(span.x, 1.0), box.y / maxf(span.y, 1.0))
	var out := PackedVector2Array()
	for p in src:
		var q: Vector2 = (p - min_p) * scale
		q.y = box.y - q.y
		out.append(q + Vector2(10, 10))
	return out


func _walls_as_points() -> PackedVector2Array:
	var parsed: Variant = JSON.parse_string(Session.sceneir_json())
	if typeof(parsed) != TYPE_DICTIONARY:
		return PackedVector2Array()
	var storeys: Array = parsed.get("storeys", [])
	if storeys.is_empty() or typeof(storeys[0]) != TYPE_DICTIONARY:
		return PackedVector2Array()
	var walls: Array = storeys[0].get("walls", [])
	var out := PackedVector2Array()
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		var pa := Vector2(float(a.get("x", 0)), float(a.get("y", 0)))
		var pb := Vector2(float(b.get("x", 0)), float(b.get("y", 0)))
		if out.is_empty():
			out.append(pa)
		out.append(pb)
	return out


## Headless / capture helpers.
func mark_guided(length_mm: float = 3000.0) -> void:
	_next_len = maxf(length_mm, MIN_MM)
	_mark_guide()


func load_demo_room(width_mm: float = 4000.0, depth_mm: float = 3000.0) -> String:
	Session.start_ar_scan(true)
	_points = PackedVector2Array()
	var err := Session.ar_demo_rectangle(width_mm, depth_mm)
	if err != "":
		return err
	_points = PackedVector2Array([
		Vector2(0, 0), Vector2(width_mm, 0), Vector2(width_mm, depth_mm), Vector2(0, depth_mm), Vector2(0, 0)
	])
	_refresh_chrome()
	return ""
