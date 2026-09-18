extends Control
## JoyPlan three-zone floating chrome (frosted pills). Visualization only.

signal back_pressed
signal mode_pressed(id: String)
signal lwh_pressed(axis: String)
signal floor_pressed
signal rail_pressed(id: String)
signal undo_pressed
signal redo_pressed
signal lighting_pressed
signal primary_pressed
signal stick_moved(v: Vector2)

var active_mode := "cube"
var show_rail := false
var show_bottom := false
var show_joystick := false
var compact := false

var _mode_btns: Dictionary = {}
var _l_btn: Button
var _w_btn: Button
var _h_btn: Button
var _floor_btn: Button
var _rail: Control
var _bottom: Control
var _stick: Control
var _stick_knob: Control
var _stick_vec := Vector2.ZERO
var _stick_held := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top()
	if show_rail:
		_build_rail()
	if show_bottom:
		_build_bottom()


func set_active_mode(id: String) -> void:
	active_mode = id
	for k in _mode_btns.keys():
		_style_icon(_mode_btns[k], k == active_mode)


func set_lwh(l_mm: float, w_mm: float, h_mm: float) -> void:
	if _l_btn:
		_l_btn.text = "L %d" % int(round(l_mm))
	if _w_btn:
		_w_btn.text = "W %d" % int(round(w_mm))
	if _h_btn:
		_h_btn.text = "H %d" % int(round(h_mm))


func set_floor_label(text: String) -> void:
	if _floor_btn:
		_floor_btn.text = text


func set_rail_visible(on: bool) -> void:
	if _rail:
		_rail.visible = on and not compact


func set_bottom_visible(on: bool) -> void:
	if _bottom:
		_bottom.visible = on and not compact


func set_compact(on: bool) -> void:
	compact = on
	if _rail:
		_rail.visible = show_rail and not compact
	if _bottom:
		_bottom.visible = show_bottom and not compact


func stick_vector() -> Vector2:
	return _stick_vec


func _build_top() -> void:
	var top := MarginContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.anchor_bottom = 0.0
	top.offset_left = 10
	top.offset_top = 10
	top.offset_right = -10
	top.offset_bottom = 96
	add_child(top)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_child(row)

	row.add_child(_circle_btn("‹", func(): back_pressed.emit(), 40))

	var cluster := VBoxContainer.new()
	cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cluster.add_theme_constant_override("separation", 6)
	var modes := PanelContainer.new()
	modes.add_theme_stylebox_override("panel", _frost_pill())
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 2)
	mrow.add_theme_constant_override("margin_left", 4)
	modes.add_child(mrow)
	for spec in [["plan", "平"], ["cube", "立"], ["roam", "人"], ["expand", "⛶"]]:
		var id := str(spec[0])
		var b := _icon_btn(str(spec[1]), func():
			if id == "expand":
				set_compact(not compact)
			set_active_mode(id if id != "expand" else active_mode)
			mode_pressed.emit(id)
		, 36, id == active_mode)
		_mode_btns[id] = b
		mrow.add_child(b)
	cluster.add_child(modes)

	var lwh := PanelContainer.new()
	lwh.add_theme_stylebox_override("panel", _frost_pill())
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 2)
	_l_btn = _text_btn("L 0", func(): lwh_pressed.emit("l"))
	_w_btn = _text_btn("W 0", func(): lwh_pressed.emit("w"))
	_h_btn = _text_btn("H 0", func(): lwh_pressed.emit("h"))
	lrow.add_child(_l_btn)
	lrow.add_child(_w_btn)
	lrow.add_child(_h_btn)
	lwh.add_child(lrow)
	cluster.add_child(lwh)
	row.add_child(cluster)

	var grow := Control.new()
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)
	_floor_btn = _pill_btn("1F", func(): floor_pressed.emit())
	_floor_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_floor_btn)
	set_active_mode(active_mode)


func _build_rail() -> void:
	_rail = PanelContainer.new()
	_rail.add_theme_stylebox_override("panel", _frost_pill())
	_rail.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_rail.anchor_left = 1.0
	_rail.anchor_right = 1.0
	_rail.anchor_top = 0.5
	_rail.anchor_bottom = 0.5
	_rail.offset_left = -54
	_rail.offset_right = -10
	_rail.offset_top = -148
	_rail.offset_bottom = 148
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for spec in [["save", "↓"], ["settings", "⚙"], ["message", "✉"], ["eye", "目"], ["cube", "盒"], ["pencil", "✎"], ["more", "···"]]:
		col.add_child(_icon_btn(str(spec[1]), func(): rail_pressed.emit(str(spec[0])), 36, false))
	_rail.add_child(col)
	add_child(_rail)


func _build_bottom() -> void:
	_bottom = MarginContainer.new()
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.anchor_top = 1.0
	_bottom.offset_left = 12
	_bottom.offset_right = -12
	_bottom.offset_top = -128
	_bottom.offset_bottom = -16
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_circle_btn("↶", func(): undo_pressed.emit(), 44))
	row.add_child(_circle_btn("↷", func(): redo_pressed.emit(), 44))
	var grow := Control.new()
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)
	if show_joystick:
		_stick = _make_stick()
		_stick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(_stick)
	var sun := _circle_btn("☀", func(): lighting_pressed.emit(), 48)
	sun.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sun)
	var go := _circle_btn("➤", func(): primary_pressed.emit(), 56)
	_tint_green(go)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(go)
	_bottom.add_child(row)
	add_child(_bottom)


func _make_stick() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(96, 96)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var disk := PanelContainer.new()
	disk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disk.add_theme_stylebox_override("panel", _frost_circle(Color(1, 1, 1, 0.78)))
	wrap.add_child(disk)
	_stick_knob = Panel.new()
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ksb := _frost_circle(Color(1, 1, 1, 0.95))
	ksb.shadow_size = 6
	_stick_knob.add_theme_stylebox_override("panel", ksb)
	_stick_knob.size = Vector2(36, 36)
	wrap.add_child(_stick_knob)
	wrap.gui_input.connect(func(ev: InputEvent): _on_stick_input(wrap, ev))
	wrap.resized.connect(func(): _place_knob(wrap, Vector2.ZERO))
	call_deferred("_place_knob", wrap, Vector2.ZERO)
	return wrap


func _on_stick_input(wrap: Control, ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_stick_held = mb.pressed
		if not mb.pressed:
			_stick_vec = Vector2.ZERO
			_place_knob(wrap, Vector2.ZERO)
			stick_moved.emit(Vector2.ZERO)
		else:
			_stick_from(wrap, mb.position)
	elif ev is InputEventMouseMotion and _stick_held:
		_stick_from(wrap, (ev as InputEventMouseMotion).position)
	elif ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		_stick_held = st.pressed
		if not st.pressed:
			_stick_vec = Vector2.ZERO
			_place_knob(wrap, Vector2.ZERO)
			stick_moved.emit(Vector2.ZERO)
		else:
			_stick_from(wrap, st.position)
	elif ev is InputEventScreenDrag:
		_stick_from(wrap, (ev as InputEventScreenDrag).position)


func _stick_from(wrap: Control, local: Vector2) -> void:
	var c := wrap.size * 0.5
	var delta := local - c
	var max_r := minf(c.x, c.y) - 18.0
	if delta.length() > max_r:
		delta = delta.normalized() * max_r
	_stick_vec = delta / max_r
	_place_knob(wrap, delta)
	stick_moved.emit(_stick_vec)


func _place_knob(wrap: Control, delta: Vector2) -> void:
	if _stick_knob == null:
		return
	var c := wrap.size * 0.5
	_stick_knob.position = c + delta - _stick_knob.size * 0.5


func _circle_btn(glyph: String, cb: Callable, size: float) -> Button:
	var b := Button.new()
	b.text = glyph
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(size, size)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 16 if size < 50 else 18)
	b.pressed.connect(cb)
	var sb := _frost_circle(Color(1, 1, 1, 0.86))
	b.add_theme_stylebox_override("normal", sb)
	var h := _frost_circle(Color(1, 1, 1, 0.96))
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", Tokens.TEXT)
	b.add_theme_color_override("font_hover_color", Tokens.TEXT)
	b.add_theme_color_override("font_pressed_color", Tokens.TEXT)
	return b


func _icon_btn(glyph: String, cb: Callable, size: float, selected: bool) -> Button:
	var b := Button.new()
	b.text = glyph
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(size, size)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 16 if size < 50 else 18)
	b.pressed.connect(cb)
	_style_icon(b, selected)
	return b


func _style_icon(b: Button, selected: bool) -> void:
	var fill := Color(0.16, 0.17, 0.20, 0.88) if selected else Color(1, 1, 1, 0.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(999)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate()
	hov.bg_color = Color(0.16, 0.17, 0.20, 0.55) if not selected else fill
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	var ink := Tokens.TEXT_ON_ACCENT if selected else Tokens.TEXT
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)


func _text_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(64, 28)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(cb)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_color_override("font_color", Tokens.TEXT)
	b.add_theme_color_override("font_hover_color", Tokens.PRIMARY)
	return b


func _pill_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(40, 36)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(cb)
	b.add_theme_stylebox_override("normal", _frost_pill())
	var h := _frost_pill()
	h.bg_color = Color(1, 1, 1, 0.95)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", Tokens.TEXT)
	return b


func _tint_green(b: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.SUCCESS
	sb.set_corner_radius_all(999)
	sb.shadow_color = Color(0.12, 0.4, 0.18, 0.28)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 2)
	b.add_theme_stylebox_override("normal", sb)
	var h := sb.duplicate()
	h.bg_color = Color("2B8A3E")
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", Tokens.TEXT_ON_ACCENT)
	b.add_theme_color_override("font_hover_color", Tokens.TEXT_ON_ACCENT)
	b.add_theme_color_override("font_pressed_color", Tokens.TEXT_ON_ACCENT)


func _frost_pill() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.82)
	sb.set_corner_radius_all(Tokens.R_PILL)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0.10, 0.12, 0.16, 0.14)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 2)
	sb.border_color = Color(1, 1, 1, 0.55)
	sb.set_border_width_all(1)
	return sb


func _frost_circle(fill: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(999)
	sb.shadow_color = Color(0.10, 0.12, 0.16, 0.16)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 2)
	sb.border_color = Color(1, 1, 1, 0.5)
	sb.set_border_width_all(1)
	return sb
