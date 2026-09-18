extends Control
## S2 Scale Calibration: fullscreen photo, island chrome, circular loupe, dark sheet.

signal calibrated(mm_per_px: float, pixel_len: float, real_mm: float)
signal skipped

const PageIslands := preload("res://app/ui/page_islands.gd")

var _img: Image
var _photo: TextureRect
var _scale_layer: Control
var _mm: LineEdit
var _hint: Label
var _loupe: Control
var _loupe_tex: TextureRect
var _loupe_cross: Control
var _a := Vector2(80, 200)
var _b := Vector2(280, 200)
var _drag := 0  # 1 = A, 2 = B
var _handle_r := 14.0
const LOUPE_SRC := 36
const LOUPE_DST := 112
const LOUPE_ZOOM := 3.1


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Studio.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Color("1A1A1C")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_photo = TextureRect.new()
	_photo.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_photo)

	_scale_layer = Control.new()
	_scale_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_scale_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scale_layer.draw.connect(_draw_scale)
	add_child(_scale_layer)
	resized.connect(func():
		if _scale_layer:
			_scale_layer.queue_redraw()
	)

	var title := PageIslands.scale_title(func(): _hint.text = "把比例尺放到已知边上，输入真实长度。")
	# Island copy must stay in this screen file for clone invariants.
	title.set_meta("label", "比例设置")
	add_child(PageIslands.top_bar(
		func(): skipped.emit(),
		title,
		func(): _hint.text = "多层楼层 P1"
	))

	_build_dark_sheet()
	_build_loupe()


func _build_dark_sheet() -> void:
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", PageIslands.dark_sheet_style())
	sheet.set_anchors_preset(PRESET_BOTTOM_WIDE)
	sheet.anchor_top = 1.0
	sheet.offset_top = -236
	sheet.offset_bottom = 0
	var col := Studio.vbox(Tokens.S1)
	var title_row := Studio.hbox(6)
	var arrow := Studio.label("⌃", Tokens.FONT_SECTION, Tokens.PAGE_PINK)
	title_row.add_child(arrow)
	title_row.add_child(Studio.label("调整户型", Tokens.FONT_SECTION, Color.WHITE))
	col.add_child(title_row)
	_hint = Studio.label("把比例尺放到已知边上", Tokens.FONT_CAPTION, Color(1, 1, 1, 0.72), true)
	col.add_child(_hint)
	col.add_child(Studio.label("请输入比例尺长度", Tokens.FONT_CAPTION, Color(1, 1, 1, 0.55)))
	var measure := Studio.hbox(Tokens.S1)
	_mm = LineEdit.new()
	_mm.placeholder_text = "例如 900"
	_mm.text = "900"
	_mm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mm.custom_minimum_size = Vector2(0, 44)
	_mm.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	measure.add_child(_mm)
	measure.add_child(Studio.label("mm", Tokens.FONT_BODY, Color(1, 1, 1, 0.7)))
	col.add_child(measure)
	var actions := Studio.hbox(Tokens.S2)
	var exit_b := PageIslands.gray_btn("退出", func(): skipped.emit())
	exit_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok_b := PageIslands.pink_btn("确定", func(): _commit())
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
	_loupe.custom_minimum_size = Vector2(124, 124)
	_loupe.size = Vector2(124, 124)
	var ring := PanelContainer.new()
	ring.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color.WHITE
	lsb.set_border_width_all(4)
	lsb.border_color = Color.WHITE
	lsb.set_corner_radius_all(999)
	lsb.shadow_color = Color(0.05, 0.06, 0.08, 0.35)
	lsb.shadow_size = 16
	lsb.shadow_offset = Vector2(0, 4)
	lsb.content_margin_left = 4
	lsb.content_margin_right = 4
	lsb.content_margin_top = 4
	lsb.content_margin_bottom = 4
	ring.add_theme_stylebox_override("panel", lsb)
	var view := Control.new()
	view.custom_minimum_size = Vector2(112, 112)
	view.clip_contents = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe_tex = TextureRect.new()
	_loupe_tex.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loupe_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_loupe_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_loupe_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(_loupe_tex)
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	if (dot(p, p) > 1.0) discard;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	_loupe_tex.material = mat
	_loupe_cross = Control.new()
	_loupe_cross.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_loupe_cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe_cross.draw.connect(_draw_loupe_cross)
	view.add_child(_loupe_cross)
	ring.add_child(view)
	_loupe.add_child(ring)
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
	if _scale_layer:
		_scale_layer.queue_redraw()
	return true


func _fitted() -> Rect2:
	if _img == null or _photo == null:
		return Rect2()
	var gr := _photo.get_global_rect()
	var origin: Vector2 = get_global_transform().affine_inverse() * gr.position
	var sz: Vector2 = gr.size
	var isz := Vector2(_img.get_width(), _img.get_height())
	if isz.x < 1.0 or isz.y < 1.0 or sz.x < 1.0 or sz.y < 1.0:
		return Rect2(origin, sz)
	var sc: float = minf(sz.x / isz.x, sz.y / isz.y)
	var vis := isz * sc
	return Rect2(origin + (sz - vis) * 0.5, vis)


func _img_to_ctrl(p: Vector2) -> Vector2:
	var r := _fitted()
	if r.size.x < 1.0:
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
	if _img == null or _scale_layer == null:
		return
	var r := _fitted()
	if r.size.x > 1.0 and r.size.y > 1.0:
		_scale_layer.draw_rect(r, Tokens.PAGE_WASH, true)
	var pa := _img_to_ctrl(_a)
	var pb := _img_to_ctrl(_b)
	_scale_layer.draw_line(pa, pb, Tokens.PRIMARY, 4.0)
	_draw_handle(pa)
	_draw_handle(pb)


func _draw_handle(p: Vector2) -> void:
	if _scale_layer == null:
		return
	_scale_layer.draw_circle(p, _handle_r + 4.0, Color.WHITE)
	_scale_layer.draw_circle(p, _handle_r, Tokens.PRIMARY)
	_scale_layer.draw_circle(p, 4.0, Color.WHITE)


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
			if _scale_layer:
				_scale_layer.queue_redraw()
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
			if _scale_layer:
				_scale_layer.queue_redraw()
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
	if _scale_layer:
		_scale_layer.queue_redraw()


func preview_loupe() -> void:
	if _img == null:
		return
	_show_loupe(_a)


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
	if _loupe_cross:
		_loupe_cross.queue_redraw()
	var ctrl := _img_to_ctrl(img_pt)
	var lw := 124.0
	var lh := 124.0
	var above := ctrl.y - lh - 28.0
	var left := ctrl.x - lw * 0.5
	if above < 8.0:
		above = ctrl.y + 28.0
	_loupe.position = Vector2(
		clampf(left, 8.0, maxf(size.x - lw - 8.0, 8.0)),
		clampf(above, 8.0, maxf(size.y - lh - 8.0, 8.0))
	)
	_loupe.visible = true
	_loupe.move_to_front()


func _draw_loupe_cross() -> void:
	if _loupe_cross == null:
		return
	var s: Vector2 = _loupe_cross.size
	if s.x < 4.0 or s.y < 4.0:
		s = Vector2(LOUPE_DST, LOUPE_DST)
	var c := s * 0.5
	var ink := Tokens.PRIMARY
	var halo := Color(1, 1, 1, 0.92)
	_loupe_cross.draw_line(Vector2(c.x, 8), Vector2(c.x, s.y - 8), halo, 3.0)
	_loupe_cross.draw_line(Vector2(8, c.y), Vector2(s.x - 8, c.y), halo, 3.0)
	_loupe_cross.draw_line(Vector2(c.x, 8), Vector2(c.x, s.y - 8), ink, 1.2)
	_loupe_cross.draw_line(Vector2(8, c.y), Vector2(s.x - 8, c.y), ink, 1.2)
	_loupe_cross.draw_arc(c, 10.0, 0.0, TAU, 32, ink, 1.4)
	_loupe_cross.draw_circle(c, 2.2, ink)


func _commit() -> void:
	if _img == null:
		skipped.emit()
		return
	var px := _a.distance_to(_b)
	var real_mm := _mm.text.strip_edges().to_float()
	if px < 4.0 or real_mm < 10.0:
		_hint.text = "两点要拉开，并且长度至少 10 mm。"
		return
	var mm_per_px := real_mm / px
	calibrated.emit(mm_per_px, px, real_mm)
