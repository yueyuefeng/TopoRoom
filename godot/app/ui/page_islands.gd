class_name PageIslands
extends Object
## Floating island chrome (JoyPlan video S2–S7). Visualization only.


static func frost(fill: Color = Tokens.PAGE_ISLAND, radius: int = Tokens.R_PILL) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(radius)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.shadow_color = Color(0.08, 0.10, 0.14, 0.22)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 3)
	s.anti_aliasing = true
	return s


static func circle_style(fill: Color, d: float) -> StyleBoxFlat:
	var s := frost(fill, int(d))
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s


static func circle_btn(glyph: String, cb: Callable, d: float = 40.0, fill: Color = Tokens.PAGE_ISLAND, ink: Color = Tokens.TEXT) -> Button:
	var b := Button.new()
	b.text = glyph
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(d, d)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 18 if d >= 44.0 else 16)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	var n := circle_style(fill, d)
	var h := circle_style(fill.darkened(0.06), d)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", n)
	b.pressed.connect(cb)
	return b


static func pill_btn(text: String, cb: Callable, min_w: float = 44.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(min_w, 36)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", Tokens.FONT_CHIP)
	b.add_theme_color_override("font_color", Tokens.TEXT)
	b.add_theme_color_override("font_hover_color", Tokens.TEXT)
	var n := frost()
	n.content_margin_left = 14
	n.content_margin_right = 14
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.pressed.connect(cb)
	return b


static func view_toggle(selected_2d: bool, on_2d: Callable, on_3d: Callable) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", frost())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	wrap.add_child(row)
	row.add_child(_seg("▦", selected_2d, on_2d))
	row.add_child(_seg("▣", not selected_2d, on_3d))
	return wrap


static func _seg(glyph: String, on: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = glyph
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(44, 32)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 16)
	var fill := Color(0.12, 0.12, 0.14, 1) if on else Color(0, 0, 0, 0)
	var ink := Color.WHITE if on else Tokens.TEXT_SECONDARY
	var n := StyleBoxFlat.new()
	n.bg_color = fill
	n.set_corner_radius_all(Tokens.R_PILL)
	n.content_margin_left = 10
	n.content_margin_right = 10
	n.content_margin_top = 4
	n.content_margin_bottom = 4
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.add_theme_stylebox_override("focus", n)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.pressed.connect(cb)
	return b


static func top_bar(on_back: Callable, center: Control, on_floor: Callable) -> MarginContainer:
	var top := MarginContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.anchor_bottom = 0.0
	top.offset_left = 12
	top.offset_top = 12
	top.offset_right = -12
	top.offset_bottom = 64
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(circle_btn("‹", on_back, 40))
	var grow_l := Control.new()
	grow_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grow_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow_l)
	if center:
		center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(center)
	var grow_r := Control.new()
	grow_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grow_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow_r)
	row.add_child(pill_btn("1F", on_floor, 48))
	top.add_child(row)
	return top


static func scale_title(on_info: Callable) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", frost())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lab := Studio.label("比例设置", Tokens.FONT_CHIP, Tokens.TEXT)
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lab)
	var info := circle_btn("i", on_info, 28, Tokens.SURFACE_MUTED, Tokens.TEXT_SECONDARY)
	info.custom_minimum_size = Vector2(28, 28)
	row.add_child(info)
	wrap.add_child(row)
	return wrap


static func readout_pill() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := frost()
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


static func bottom_2d_dock(on_3d: Callable, on_compass: Callable, on_save: Callable) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", frost())
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wrap.anchor_left = 0.5
	wrap.anchor_right = 0.5
	wrap.anchor_top = 1.0
	wrap.offset_left = -92
	wrap.offset_right = 92
	wrap.offset_top = -78
	wrap.offset_bottom = -18
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var go := circle_btn("▶", on_3d, 44, Tokens.PAGE_GREEN, Color.WHITE)
	row.add_child(go)
	row.add_child(circle_btn("◎", on_compass, 40))
	row.add_child(circle_btn("↓", on_save, 40))
	wrap.add_child(row)
	return wrap


static func green_back_2d(on_2d: Callable) -> Button:
	var b := circle_btn("▦", on_2d, 52, Tokens.PAGE_GREEN, Color.WHITE)
	b.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	b.anchor_right = 0.0
	b.anchor_top = 1.0
	b.offset_left = 16
	b.offset_top = -76
	b.offset_right = 68
	b.offset_bottom = -24
	return b


static func undo_redo_pill(on_undo: Callable, on_redo: Callable) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", frost())
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	wrap.anchor_left = 1.0
	wrap.anchor_top = 1.0
	wrap.offset_left = -132
	wrap.offset_right = -16
	wrap.offset_top = -72
	wrap.offset_bottom = -20
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(circle_btn("↶", on_undo, 40, Color(0, 0, 0, 0)))
	row.add_child(circle_btn("↷", on_redo, 40, Color(0, 0, 0, 0)))
	wrap.add_child(row)
	return wrap


static func right_circles(actions: Array) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	col.anchor_left = 1.0
	col.anchor_right = 1.0
	col.offset_left = -56
	col.offset_right = -12
	col.offset_top = -160
	col.offset_bottom = 160
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for spec in actions:
		var id := str(spec[0])
		var glyph := str(spec[1])
		var cb: Callable = spec[2]
		col.add_child(circle_btn(glyph, cb, 44))
		col.set_meta("last_id", id)
	return col


static func dark_sheet_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Tokens.PAGE_DARK
	s.corner_radius_top_left = 22
	s.corner_radius_top_right = 22
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 20
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 18
	s.anti_aliasing = true
	return s


static func white_sheet_style() -> StyleBoxFlat:
	var s := frost(Tokens.PAGE_ISLAND, 22)
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 16
	return s


static func pink_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(120, 44)
	b.add_theme_font_override("font", Studio.font)
	var n := StyleBoxFlat.new()
	n.bg_color = Tokens.PAGE_PINK
	n.set_corner_radius_all(Tokens.R_PILL)
	n.content_margin_left = 18
	n.content_margin_right = 18
	var h := n.duplicate()
	h.bg_color = Tokens.PAGE_PINK_HOVER
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(cb)
	return b


static func gray_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(100, 44)
	b.add_theme_font_override("font", Studio.font)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.38, 0.38, 0.40, 1)
	n.set_corner_radius_all(Tokens.R_PILL)
	n.content_margin_left = 18
	n.content_margin_right = 18
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(cb)
	return b


static func purple_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(120, 44)
	b.add_theme_font_override("font", Studio.font)
	var n := StyleBoxFlat.new()
	n.bg_color = Tokens.PAGE_PURPLE
	n.set_corner_radius_all(Tokens.R_PILL)
	n.content_margin_left = 18
	n.content_margin_right = 18
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(cb)
	return b
