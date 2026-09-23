class_name FlowIslands
extends Object
## Floating island chrome only: white capsules, detached circles, drop shadows.
## No edge-to-edge nav bars. No primary FAB as main nav.


static func frost(fill: Color = Tokens.PAGE_ISLAND, radius: int = Tokens.R_PILL) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.shadow_color = Color(0.08, 0.10, 0.14, 0.22)
	s.shadow_size = 14
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


static func _seg(glyph: String, on: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = glyph
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(48, 32)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 16)
	var fill := Color(0.12, 0.12, 0.14, 1) if on else Color(0, 0, 0, 0)
	var ink := Color.WHITE if on else Tokens.TEXT_SECONDARY
	var n := StyleBoxFlat.new()
	n.bg_color = fill
	n.set_corner_radius_all(Tokens.R_PILL)
	n.content_margin_left = 12
	n.content_margin_right = 12
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


static func view_toggle(selected_2d: bool, on_2d: Callable, on_3d: Callable) -> PanelContainer:
	return mode_capsule(0 if selected_2d else 1, on_2d, on_3d, Callable(), Callable())


static func mode_capsule(selected: int, on_2d: Callable, on_3d: Callable, on_walk: Callable, on_crop: Callable) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", frost())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	wrap.add_child(row)
	var glyphs := ["▦", "▣", "🚶", "⛶"]
	var cbs: Array = [
		on_2d if on_2d.is_valid() else Callable(),
		on_3d if on_3d.is_valid() else Callable(),
		on_walk if on_walk.is_valid() else Callable(),
		on_crop if on_crop.is_valid() else Callable(),
	]
	for i in glyphs.size():
		var cb: Callable = cbs[i]
		row.add_child(_seg(glyphs[i], i == selected, cb if cb.is_valid() else func(): pass))
	return wrap


## JoyPlan-style bottom compass: the four-icon view-mode pill, not a top strip.
static func mode_compass(selected: int, on_2d: Callable, on_3d: Callable, on_walk: Callable, on_crop: Callable) -> PanelContainer:
	var wrap := mode_capsule(selected, on_2d, on_3d, on_walk, on_crop)
	wrap.name = "ModeCompass"
	wrap.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	wrap.anchor_left = 0.5
	wrap.anchor_right = 0.5
	wrap.anchor_top = 1.0
	wrap.offset_left = -124
	wrap.offset_right = 124
	wrap.offset_top = -96
	wrap.offset_bottom = -28
	return wrap


static func dark_readout() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := frost(Color(0.12, 0.12, 0.14, 0.92), Tokens.R_PILL)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


static func green_fab(glyph: String, cb: Callable, d: float = 56.0) -> Button:
	var b := circle_btn(glyph, cb, d, Tokens.PAGE_GREEN, Color.WHITE)
	b.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	b.anchor_right = 0.0
	b.anchor_top = 1.0
	b.offset_left = 18
	b.offset_top = -86
	b.offset_right = 18 + d
	b.offset_bottom = -30
	return b


static func plus_fab(cb: Callable) -> Button:
	var b := circle_btn("+", cb, 52, Tokens.PAGE_GREEN, Color.WHITE)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.anchor_left = 1.0
	b.anchor_top = 1.0
	b.offset_left = -72
	b.offset_top = -236
	b.offset_right = -20
	b.offset_bottom = -184
	return b


static func tool_cluster(on_pan: Callable, on_layers: Callable) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	col.anchor_left = 1.0
	col.anchor_top = 1.0
	col.offset_left = -68
	col.offset_right = -16
	col.offset_top = -168
	col.offset_bottom = -56
	col.add_child(circle_btn("✥", on_pan, 44))
	col.add_child(circle_btn("☰", on_layers, 44))
	return col


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
	wrap.add_theme_stylebox_override("panel", frost(Color(1, 1, 1, 0.18), Tokens.R_PILL))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lab := Studio.label("Scale setting", Tokens.FONT_CHIP, Color.WHITE)
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lab)
	var info := circle_btn("i", on_info, 28, Color(1, 1, 1, 0.22), Color.WHITE)
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
	wrap.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	wrap.anchor_left = 0.5
	wrap.anchor_right = 0.5
	wrap.anchor_top = 1.0
	wrap.offset_left = -96
	wrap.offset_right = 96
	wrap.offset_top = -86
	wrap.offset_bottom = -22
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(circle_btn("▶", on_3d, 44, Tokens.PAGE_GREEN, Color.WHITE))
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
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	wrap.anchor_left = 0.0
	wrap.anchor_top = 1.0
	wrap.offset_left = 84
	wrap.offset_right = 212
	wrap.offset_top = -80
	wrap.offset_bottom = -28
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
	col.offset_top = -180
	col.offset_bottom = 180
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for spec in actions:
		var glyph := str(spec[1])
		var cb: Callable = spec[2]
		col.add_child(circle_btn(glyph, cb, 44))
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
	return _fill_btn(text, cb, Tokens.PAGE_PINK, Tokens.PAGE_PINK_HOVER, Color.WHITE, 120)


static func gray_btn(text: String, cb: Callable) -> Button:
	return _fill_btn(text, cb, Color(0.38, 0.38, 0.40, 1), Color(0.32, 0.32, 0.34, 1), Color.WHITE, 100)


static func purple_btn(text: String, cb: Callable) -> Button:
	return _fill_btn(text, cb, Tokens.PAGE_PURPLE, Tokens.PAGE_PURPLE.darkened(0.08), Color.WHITE, 120)


static func _fill_btn(text: String, cb: Callable, fill: Color, hover: Color, ink: Color, min_w: float) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(min_w, 44)
	b.add_theme_font_override("font", Studio.font)
	var n := StyleBoxFlat.new()
	n.bg_color = fill
	n.set_corner_radius_all(Tokens.R_PILL)
	n.content_margin_left = 18
	n.content_margin_right = 18
	var h := n.duplicate()
	h.bg_color = hover
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.pressed.connect(cb)
	return b


static func ctx_pill(actions: Array) -> PanelContainer:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", frost())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	for spec in actions:
		var b := Button.new()
		b.text = str(spec[0])
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(52, 36)
		b.add_theme_font_override("font", Studio.font)
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", Tokens.TEXT)
		var empty := StyleBoxEmpty.new()
		b.add_theme_stylebox_override("normal", empty)
		b.add_theme_stylebox_override("hover", empty)
		b.add_theme_stylebox_override("pressed", empty)
		var cb: Callable = spec[1]
		b.pressed.connect(cb)
		row.add_child(b)
	wrap.add_child(row)
	return wrap
