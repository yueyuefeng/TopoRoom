extends Object
## Marketing chrome matching the JoyPlan click-path screenshots:
## orange primary, 2×2 home cards, white/dark bottom capsule nav.


static func fill(bg: Color, r: int = 18, shadow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(r)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.anti_aliasing = true
	if shadow:
		s.shadow_color = Color(0.05, 0.05, 0.08, 0.28)
		s.shadow_size = 12
		s.shadow_offset = Vector2(0, 4)
	return s


static func color_btn(text: String, bg: Color, ink: Color, cb: Callable, min_h: float = 88.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, min_h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	var n := fill(bg, 22)
	var h := fill(bg.lightened(0.06), 22)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.pressed.connect(cb)
	return b


static func icon_btn(glyph: String, cb: Callable, d: float = 40.0, ink: Color = Tokens.TEXT) -> Button:
	var b := Button.new()
	b.text = glyph
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.custom_minimum_size = Vector2(d, d)
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.pressed.connect(cb)
	return b


static func step_bar(title: String, action: String, on_back: Callable, on_action: Callable, action_ink: Color = Tokens.JP_ORANGE) -> PanelContainer:
	var bar := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.content_margin_left = 8
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	bar.add_theme_stylebox_override("panel", sb)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.anchor_bottom = 0.0
	bar.offset_bottom = 56
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(icon_btn("‹", on_back, 44))
	var lab := Studio.label(title, Tokens.FONT_SECTION, Tokens.TEXT)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.clip_text = true
	row.add_child(lab)
	var act := Button.new()
	act.text = action
	act.focus_mode = Control.FOCUS_NONE
	act.flat = true
	act.add_theme_font_override("font", Studio.font)
	act.add_theme_font_size_override("font_size", 16)
	act.add_theme_color_override("font_color", action_ink)
	act.add_theme_color_override("font_hover_color", action_ink)
	act.pressed.connect(on_action)
	row.add_child(act)
	bar.add_child(row)
	return bar


static func bottom_nav(active: String, on_home: Callable, on_projects: Callable, on_me: Callable, dark: bool = false) -> PanelContainer:
	var wrap := PanelContainer.new()
	var sb := fill(Color(0.10, 0.10, 0.12, 0.88) if dark else Color.WHITE, 32, true)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	wrap.anchor_left = 0.5
	wrap.anchor_right = 0.5
	wrap.anchor_top = 1.0
	wrap.offset_left = -148
	wrap.offset_right = 148
	wrap.offset_top = -86
	wrap.offset_bottom = -22
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_nav_item("⌂", active == "home", on_home, dark))
	row.add_child(_nav_item("▦", active == "projects", on_projects, dark))
	row.add_child(_nav_item("☺", active == "me", on_me, dark))
	wrap.add_child(row)
	return wrap


static func _nav_item(glyph: String, on: bool, cb: Callable, dark: bool) -> Button:
	var b := Button.new()
	b.text = glyph
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(84, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 22)
	var ink := Color.WHITE if on else (Color(0.75, 0.75, 0.78) if dark else Tokens.TEXT_SECONDARY)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	var n := StyleBoxFlat.new()
	if on:
		n.bg_color = Tokens.JP_ORANGE
		n.set_corner_radius_all(24)
	else:
		n.bg_color = Color(0, 0, 0, 0)
	n.content_margin_left = 8
	n.content_margin_right = 8
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.pressed.connect(cb)
	return b


static func list_row(title: String, subtitle: String, glyph: String, cb: Callable, badge: String = "") -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 88)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := fill(Color.WHITE, 18, false)
	sb.border_color = Color("EEEEEE")
	sb.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(cb)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.offset_top = 12
	row.offset_bottom = -12
	row.add_theme_constant_override("separation", 14)
	var ic := PanelContainer.new()
	var ic_sb := StyleBoxFlat.new()
	ic_sb.bg_color = Color("F4F4F4")
	ic_sb.set_corner_radius_all(12)
	ic.add_theme_stylebox_override("panel", ic_sb)
	ic.custom_minimum_size = Vector2(52, 52)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gl := Studio.label(glyph, 22, Tokens.TEXT)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.add_child(gl)
	row.add_child(ic)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	var t := Studio.label(title, Tokens.FONT_SECTION, Tokens.TEXT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.clip_text = true
	var s := Studio.label(subtitle, Tokens.FONT_CAPTION, Tokens.TEXT_SECONDARY)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.clip_text = true
	col.add_child(t)
	col.add_child(s)
	row.add_child(col)
	if not badge.is_empty():
		var tag := Label.new()
		tag.text = badge
		tag.add_theme_font_override("font", Studio.font)
		tag.add_theme_font_size_override("font_size", 11)
		tag.add_theme_color_override("font_color", Color.WHITE)
		var tg := StyleBoxFlat.new()
		tg.bg_color = Color(0.18, 0.18, 0.20)
		tg.set_corner_radius_all(4)
		tg.content_margin_left = 8
		tg.content_margin_right = 8
		tg.content_margin_top = 4
		tg.content_margin_bottom = 4
		tag.add_theme_stylebox_override("normal", tg)
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tag)
	b.add_child(row)
	return b
