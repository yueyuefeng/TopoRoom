extends Control
## S2 — Scale calibration: fullscreen photo, blue handles, circular loupe, dark sheet.

signal calibrated(mm_per_px: float, pixel_len: float, real_mm: float)
signal cancelled

const TITLE := "比例设置"
const LOUPE_SRC := 36
const LOUPE_DST := 120
const LOUPE_ZOOM := 3.1

var _img: Image
var _photo: TextureRect
var _mm: LineEdit
var _hint: Label
var _loupe: Control
var _loupe_tex: TextureRect
var _loupe_cross: Control
var _a := Vector2(80, 200)
var _b := Vector2(280, 200)
var _drag := 0
var _handle_r := 16.0
var _snack: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_SCALE

	_photo = TextureRect.new()
	_photo.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_photo)

	var wash := ColorRect.new()
	wash.color = Color(1, 0.78, 0.86, 0.10)
	wash.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_scale)
	overlay.name = "ScaleOverlay"
	add_child(overlay)

	add_child(FlowIslands.top_bar(
		func(): cancelled.emit(); FlowRouter.home(self),
		FlowIslands.scale_title(func(): _hint.text = "把比例尺放到已知边上，再输入真实长度"),
		func(): pass
	))

	_build_sheet()
	_build_loupe()

	_snack = preload("res://app/ui/snackbar.gd").new()
	_snack.set_anchors_preset(PRESET_TOP_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = 72
	_snack.offset_bottom = 120
	add_child(_snack)

	var path := Session.last_import_path
	if path.is_empty():
		path = Session.last_import_uri
	if path.is_empty():
		path = ProjectSettings.globalize_path("res://fixtures/apt-plan-user-01.png")
	if not load_image(path):
		_make_demo()


func _build_sheet() -> void:
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", FlowIslands.dark_sheet_style())
	sheet.set_anchors_preset(PRESET_BOTTOM_WIDE)
	sheet.anchor_top = 1.0
	sheet.offset_top = -268
	sheet.offset_bottom = 0
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var title_row := HBoxContainer.new()
	var title := Studio.label("调整户型", Tokens.FONT_SECTION, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	title_row.add_child(Studio.label("⌃", Tokens.FONT_BODY, Tokens.PAGE_PINK))
	col.add_child(title_row)
	_hint = Studio.label("把比例尺放到已知边上", Tokens.FONT_CAPTION, Color(0.82, 0.82, 0.86))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_hint)
	col.add_child(Studio.label("请输入比例尺长度", Tokens.FONT_CAPTION, Color(0.70, 0.70, 0.74)))
	_mm = LineEdit.new()
	_mm.text = "900"
	_mm.placeholder_text = "900"
	_mm.custom_minimum_size = Vector2(0, 44)
	_mm.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_mm.add_theme_color_override("font_color", Color.WHITE)
	_mm.add_theme_font_override("font", Studio.font)
	var mm_sb := StyleBoxFlat.new()
	mm_sb.bg_color = Color(0.22, 0.22, 0.24, 1)
	mm_sb.set_corner_radius_all(12)
	mm_sb.content_margin_left = 12
	mm_sb.content_margin_right = 12
	_mm.add_theme_stylebox_override("normal", mm_sb)
	col.add_child(_mm)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	var exit_b := FlowIslands.gray_btn("退出", func(): cancelled.emit(); FlowRouter.home(self))
	exit_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok_b := FlowIslands.pink_btn("确定", func(): _commit())
	ok_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(exit_b)
	actions.add_child(ok_b)
	col.add_child(actions)
	sheet.add_child(col)
	add_child(sheet)


func _build_loupe() -> void:
	_loupe = Control.new()
	_loupe.visible = false
	_loupe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe.custom_minimum_size = Vector2(LOUPE_DST + 16, LOUPE_DST + 16)
	_loupe.size = Vector2(LOUPE_DST + 16, LOUPE_DST + 16)
	_loupe.draw.connect(_draw_loupe_ring)
	var clip := Control.new()
	clip.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	clip.offset_left = 8
	clip.offset_top = 8
	clip.offset_right = -8
	clip.offset_bottom = -8
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe_tex = TextureRect.new()
	_loupe_tex.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loupe_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_loupe_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_loupe_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 p = UV - vec2(0.5);
	if (dot(p, p) > 0.25) discard;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_loupe_tex.material = mat
	clip.add_child(_loupe_tex)
	_loupe.add_child(clip)
	_loupe_cross = Control.new()
	_loupe_cross.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loupe_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe_cross.draw.connect(_draw_loupe_cross)
	_loupe.add_child(_loupe_cross)
	add_child(_loupe)


func load_image(path: String) -> bool:
	var abs_path := path
	if path.begins_with("user://") or path.begins_with("res://"):
		abs_path = ProjectSettings.globalize_path(path)
	if abs_path.is_empty() or not FileAccess.file_exists(abs_path):
		return false
	_img = Image.new()
	if _img.load(abs_path) != OK:
		return false
	_photo.texture = ImageTexture.create_from_image(_img)
	_a = Vector2(_img.get_width() * 0.28, _img.get_height() * 0.52)
	_b = Vector2(_img.get_width() * 0.72, _img.get_height() * 0.52)
	queue_redraw()
	_queue_scale()
	return true


func _make_demo() -> void:
	var fixture := ProjectSettings.globalize_path("res://fixtures/apt-plan-user-01.png")
	if FileAccess.file_exists(fixture) and load_image(fixture):
		return
	_img = Image.create(720, 960, false, Image.FORMAT_RGB8)
	_img.fill(Color("EDE8E2"))
	for y in range(80, 880):
		for x in range(60, 66):
			_img.set_pixel(x, y, Color("3A3A3A"))
			_img.set_pixel(654, y, Color("3A3A3A"))
	for x in range(60, 660):
		for y in range(80, 86):
			_img.set_pixel(x, y, Color("3A3A3A"))
			_img.set_pixel(x, 874, Color("3A3A3A"))
	_photo.texture = ImageTexture.create_from_image(_img)
	_a = Vector2(120, 480)
	_b = Vector2(520, 480)
	queue_redraw()
	_queue_scale()


func _fitted() -> Rect2:
	if _img == null or _photo == null:
		return Rect2()
	var gr := _photo.get_global_rect()
	var origin: Vector2 = get_global_transform().affine_inverse() * gr.position
	return Rect2(origin, gr.size)


func _img_to_ctrl(p: Vector2) -> Vector2:
	var r := _fitted()
	if r.size.x < 1.0 or _img == null:
		return p
	return r.position + Vector2(p.x / float(_img.get_width()) * r.size.x, p.y / float(_img.get_height()) * r.size.y)


func _ctrl_to_img(p: Vector2) -> Vector2:
	var r := _fitted()
	if r.size.x < 1.0 or _img == null:
		return p
	var q := (p - r.position) / r.size
	q.x = clampf(q.x, 0.0, 1.0)
	q.y = clampf(q.y, 0.0, 1.0)
	return Vector2(q.x * float(_img.get_width()), q.y * float(_img.get_height()))


func _draw_scale() -> void:
	var overlay := get_node_or_null("ScaleOverlay") as Control
	if overlay == null or _img == null:
		return
	var pa := _img_to_ctrl(_a)
	var pb := _img_to_ctrl(_b)
	overlay.draw_line(pa, pb, Color(0.22, 0.55, 1.0, 1), 3.0)
	_draw_handle_on(overlay, pa)
	_draw_handle_on(overlay, pb)


func _draw_handle_on(overlay: Control, p: Vector2) -> void:
	overlay.draw_circle(p, _handle_r + 3.0, Color.WHITE)
	overlay.draw_circle(p, _handle_r, Color(0.22, 0.55, 1.0, 1))
	overlay.draw_circle(p, 4.0, Color.WHITE)


func _queue_scale() -> void:
	var overlay := get_node_or_null("ScaleOverlay") as Control
	if overlay:
		overlay.queue_redraw()
	queue_redraw()


func _draw_loupe_ring() -> void:
	if _loupe == null:
		return
	var s: Vector2 = _loupe.size
	var c := s * 0.5
	var r := mini(s.x, s.y) * 0.5 - 2.0
	_loupe.draw_circle(c, r, Color(0, 0, 0, 0.18))
	_loupe.draw_arc(c, r - 1.0, 0.0, TAU, 48, Color.WHITE, 6.0)


func _draw_loupe_cross() -> void:
	if _loupe_cross == null:
		return
	var s: Vector2 = _loupe_cross.size
	if s.x < 8.0:
		s = Vector2(LOUPE_DST + 16, LOUPE_DST + 16)
	var c := s * 0.5
	var ink := Color(0.15, 0.15, 0.18)
	_loupe_cross.draw_line(Vector2(c.x, 18), Vector2(c.x, s.y - 18), Color.WHITE, 3.0)
	_loupe_cross.draw_line(Vector2(18, c.y), Vector2(s.x - 18, c.y), Color.WHITE, 3.0)
	_loupe_cross.draw_line(Vector2(c.x, 18), Vector2(c.x, s.y - 18), ink, 1.2)
	_loupe_cross.draw_line(Vector2(18, c.y), Vector2(s.x - 18, c.y), ink, 1.2)
	_loupe_cross.draw_arc(c, 10.0, 0.0, TAU, 32, ink, 1.4)


func _gui_input(event: InputEvent) -> void:
	if _img == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_drag = _hit(mb.position)
			if _drag != 0:
				_show_loupe(_ctrl_to_img(mb.position))
				accept_event()
		else:
			_drag = 0
			_loupe.visible = false
			_queue_scale()
	elif event is InputEventMouseMotion and _drag != 0:
		_set_handle(_drag, _ctrl_to_img((event as InputEventMouseMotion).position))
		_show_loupe(_ctrl_to_img((event as InputEventMouseMotion).position))
		accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_drag = _hit(st.position)
			if _drag != 0:
				_show_loupe(_ctrl_to_img(st.position))
				accept_event()
		else:
			_drag = 0
			_loupe.visible = false
			_queue_scale()
	elif event is InputEventScreenDrag and _drag != 0:
		var sd := event as InputEventScreenDrag
		_set_handle(_drag, _ctrl_to_img(sd.position))
		_show_loupe(_ctrl_to_img(sd.position))
		accept_event()


func _hit(pos: Vector2) -> int:
	if _img_to_ctrl(_a).distance_to(pos) <= _handle_r + 10.0:
		return 1
	if _img_to_ctrl(_b).distance_to(pos) <= _handle_r + 10.0:
		return 2
	return 0


func _set_handle(which: int, img_pt: Vector2) -> void:
	if which == 1:
		_a = img_pt
	else:
		_b = img_pt
	queue_redraw()
	_queue_scale()


func _show_loupe(img_pt: Vector2) -> void:
	if _img == null:
		return
	var src := LOUPE_SRC
	var x := int(clampf(img_pt.x - src * 0.5, 0.0, float(_img.get_width() - src)))
	var y := int(clampf(img_pt.y - src * 0.5, 0.0, float(_img.get_height() - src)))
	var w := mini(src, _img.get_width() - x)
	var h := mini(src, _img.get_height() - y)
	if w < 4 or h < 4:
		return
	var crop := _img.get_region(Rect2i(x, y, w, h))
	crop.resize(LOUPE_DST, LOUPE_DST, Image.INTERPOLATE_NEAREST)
	_loupe_tex.texture = ImageTexture.create_from_image(crop)
	_loupe.queue_redraw()
	if _loupe_cross:
		_loupe_cross.queue_redraw()
	var ctrl := _img_to_ctrl(img_pt)
	var lw := float(LOUPE_DST + 16)
	var above := ctrl.y - lw - 24.0
	_loupe.position = Vector2(
		clampf(ctrl.x - lw * 0.5, 8.0, maxf(size.x - lw - 8.0, 8.0)),
		clampf(above if above > 8.0 else ctrl.y + 28.0, 8.0, maxf(size.y - lw - 8.0, 8.0))
	)
	_loupe.visible = true
	_loupe.move_to_front()


func _commit() -> void:
	if _img == null:
		_run_vision(0.0)
		return
	var px := _a.distance_to(_b)
	var real_mm := _mm.text.strip_edges().to_float()
	if px < 4.0 or real_mm < 10.0:
		_hint.text = "两点要拉开，并且长度至少 10 mm。"
		return
	var mm_per_px := real_mm / px
	calibrated.emit(mm_per_px, px, real_mm)
	_run_vision(mm_per_px)


func _run_vision(mm_per_px: float) -> void:
	var uri := Session.last_import_uri
	if uri.is_empty():
		uri = Session.last_import_path
	if uri.is_empty():
		uri = "fixture:photo"
	var err := Session.import_photo_vision(uri, mm_per_px)
	if err != "":
		if _snack:
			_snack.show_message(err)
		return
	FlowRouter.edit_2d(self)
