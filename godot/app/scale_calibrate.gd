extends Control
## Two-handle scale calibration on a photo: known edge + loupe + mm sheet.

signal calibrated(mm_per_px: float, pixel_len: float, real_mm: float)
signal skipped

var _img: Image
var _photo: TextureRect
var _mm: LineEdit
var _hint: Label
var _loupe: PanelContainer
var _loupe_tex: TextureRect
var _a := Vector2(80, 200)
var _b := Vector2(280, 200)
var _drag := 0  # 1 = A, 2 = B
var _handle_r := 18.0


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Studio.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Tokens.BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", Tokens.S2)
	top.add_theme_constant_override("margin_right", Tokens.S2)
	top.add_theme_constant_override("margin_top", Tokens.S2)
	var row := Studio.hbox(Tokens.S1)
	row.add_child(Studio.ghost("跳过", func(): skipped.emit()))
	var title := Studio.section("标定比例")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(title)
	top.add_child(row)
	root.add_child(top)

	_hint = Studio.caption("把两个点拖到一条已知边上，输入真实长度（毫米）。拖动时放大镜帮你对准。")
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", Tokens.S2)
	hm.add_theme_constant_override("margin_right", Tokens.S2)
	hm.add_child(_hint)
	root.add_child(hm)

	_photo = TextureRect.new()
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_photo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_photo.custom_minimum_size = Vector2(0, 280)
	_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_photo)

	var sheet := Studio.sheet()
	var col := Studio.vbox(Tokens.S1)
	col.add_child(Studio.caption("这条边的真实长度"))
	var measure := Studio.hbox(Tokens.S1)
	_mm = LineEdit.new()
	_mm.placeholder_text = "例如 3000"
	_mm.text = "3000"
	_mm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mm.custom_minimum_size = Vector2(0, 48)
	measure.add_child(_mm)
	measure.add_child(Studio.label("mm", Tokens.FONT_BODY, Tokens.TEXT_SECONDARY))
	col.add_child(measure)
	var ok := Studio.primary("确定，开始识墙", func(): _commit())
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(ok)
	col.add_child(Studio.ghost("按墙厚自动估比例", func(): skipped.emit()))
	sheet.add_child(col)
	root.add_child(sheet)

	_loupe = PanelContainer.new()
	_loupe.visible = false
	_loupe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Tokens.SURFACE
	lsb.set_border_width_all(2)
	lsb.border_color = Tokens.PRIMARY
	lsb.set_corner_radius_all(Tokens.R_PILL)
	lsb.content_margin_left = 6
	lsb.content_margin_right = 6
	lsb.content_margin_top = 6
	lsb.content_margin_bottom = 6
	_loupe.add_theme_stylebox_override("panel", lsb)
	_loupe.custom_minimum_size = Vector2(112, 112)
	_loupe_tex = TextureRect.new()
	_loupe_tex.custom_minimum_size = Vector2(100, 100)
	_loupe_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_loupe_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_loupe.add_child(_loupe_tex)
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
	return true


func _fitted() -> Rect2:
	if _img == null or _photo == null:
		return Rect2()
	var gr := _photo.get_global_rect()
	var origin := global_to_local(gr.position)
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


func _draw() -> void:
	if _img == null:
		return
	var pa := _img_to_ctrl(_a)
	var pb := _img_to_ctrl(_b)
	draw_line(pa, pb, Tokens.PRIMARY, 3.0)
	_draw_handle(pa, "A")
	_draw_handle(pb, "B")
	var mid := (pa + pb) * 0.5 + Vector2(0, -22)
	var px := _a.distance_to(_b)
	draw_string(_font(), mid + Vector2(-36, 0), "%d px" % int(round(px)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Tokens.TEXT)


func _draw_handle(p: Vector2, tag: String) -> void:
	draw_circle(p, _handle_r + 3.0, Tokens.SURFACE)
	draw_circle(p, _handle_r, Tokens.PRIMARY)
	draw_circle(p, 4.0, Tokens.TEXT_ON_ACCENT)
	draw_string(_font(), p + Vector2(-4, -_handle_r - 6), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Tokens.PRIMARY)


func _font() -> Font:
	if Studio and Studio.font:
		return Studio.font
	return ThemeDB.fallback_font


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
			queue_redraw()
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
			queue_redraw()
	elif event is InputEventScreenDrag and _drag != 0:
		var sd := event as InputEventScreenDrag
		_set_handle(_drag, _ctrl_to_img(sd.position))
		_show_loupe(_ctrl_to_img(sd.position))
		accept_event()


func _hit(pos: Vector2) -> int:
	if _img_to_ctrl(_a).distance_to(pos) <= _handle_r + 8.0:
		return 1
	if _img_to_ctrl(_b).distance_to(pos) <= _handle_r + 8.0:
		return 2
	return 0


func _set_handle(which: int, img_pt: Vector2) -> void:
	if which == 1:
		_a = img_pt
	else:
		_b = img_pt
	queue_redraw()


func _show_loupe(img_pt: Vector2) -> void:
	if _img == null:
		return
	var src := 28
	var x := int(clampf(img_pt.x - src * 0.5, 0.0, float(_img.get_width() - src)))
	var y := int(clampf(img_pt.y - src * 0.5, 0.0, float(_img.get_height() - src)))
	var w := mini(src, _img.get_width() - x)
	var h := mini(src, _img.get_height() - y)
	if w < 4 or h < 4:
		return
	var crop := _img.get_region(Rect2i(x, y, w, h))
	crop.resize(100, 100, Image.INTERPOLATE_NEAREST)
	_loupe_tex.texture = ImageTexture.create_from_image(crop)
	var ctrl := _img_to_ctrl(img_pt)
	_loupe.position = Vector2(clampf(ctrl.x + 24.0, 8.0, size.x - 120.0), clampf(ctrl.y - 140.0, 8.0, size.y - 200.0))
	_loupe.visible = true


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
