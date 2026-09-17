extends Node
## Autoload design system: CJK font, Theme, control factories.

var font: Font
var theme: Theme


func _ready() -> void:
	font = Tokens.cjk_font()
	theme = AppTheme.build(font)


func apply_to(root: Control) -> void:
	if root == null:
		return
	root.theme = theme


func label(text: String, size_px: int = Tokens.FONT_BODY, color: Color = Tokens.TEXT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func display(text: String) -> Label:
	var l := label(text, Tokens.FONT_DISPLAY, Tokens.TEXT)
	l.add_theme_color_override("font_color", Tokens.TEXT)
	return l


func caption(text: String) -> Label:
	return label(text, Tokens.FONT_CAPTION, Tokens.TEXT_SECONDARY, true)


func section(text: String) -> Label:
	return label(text, Tokens.FONT_SECTION, Tokens.TEXT)


func button(text: String, variation: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(0, Tokens.S6)
	b.add_theme_font_override("font", font)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func primary(text: String, cb: Callable) -> Button:
	var b := button(text, "PrimaryButton", cb)
	b.custom_minimum_size = Vector2(0, 48)
	return b


func ghost(text: String, cb: Callable) -> Button:
	var b := button(text, "GhostButton", cb)
	b.custom_minimum_size = Vector2(72, 40)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


func chip(text: String, cb: Callable, on: bool = false) -> Button:
	var b := button(text, "ChipOn" if on else "ChipButton", cb)
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", Tokens.FONT_CHIP)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


func accent_chip(text: String, cb: Callable) -> Button:
	var b := button(text, "AccentChip", cb)
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", Tokens.FONT_CHIP)
	return b


func card(variation: String = "HeroCard") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func status_chip(text: String, ok: bool) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.SUCCESS_SOFT if ok else Tokens.PRIMARY_SOFT
	sb.corner_radius_top_left = Tokens.R_PILL
	sb.corner_radius_top_right = Tokens.R_PILL
	sb.corner_radius_bottom_left = Tokens.R_PILL
	sb.corner_radius_bottom_right = Tokens.R_PILL
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	var l := label(text, Tokens.FONT_CAPTION, Tokens.SUCCESS if ok else Tokens.PRIMARY)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func segmented(options: PackedStringArray, selected: int, cb: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var wrap := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Tokens.SURFACE_MUTED
	bg.corner_radius_top_left = Tokens.R_PILL
	bg.corner_radius_top_right = Tokens.R_PILL
	bg.corner_radius_bottom_left = Tokens.R_PILL
	bg.corner_radius_bottom_right = Tokens.R_PILL
	bg.content_margin_left = 4
	bg.content_margin_right = 4
	bg.content_margin_top = 4
	bg.content_margin_bottom = 4
	wrap.add_theme_stylebox_override("panel", bg)
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	wrap.add_child(inner)
	row.add_child(wrap)
	var buttons: Array[Button] = []
	for i in options.size():
		var idx: int = i
		var b := Button.new()
		b.text = options[i]
		b.toggle_mode = true
		b.button_pressed = i == selected
		b.theme_type_variation = "ChipOn" if i == selected else "ChipButton"
		b.custom_minimum_size = Vector2(72, 32)
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", Tokens.FONT_CHIP)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			for j in buttons.size():
				buttons[j].button_pressed = j == idx
				buttons[j].theme_type_variation = "ChipOn" if j == idx else "ChipButton"
			cb.call(idx, options[idx])
		)
		buttons.append(b)
		inner.add_child(b)
	return row


func vbox(sep: int = Tokens.S2) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", sep)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return col


func hbox(sep: int = Tokens.S1) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", sep)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row


func flow() -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", Tokens.S1)
	f.add_theme_constant_override("v_separation", Tokens.S1)
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return f


func spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func attach_hud(parent: Node) -> Dictionary:
	var layer := CanvasLayer.new()
	parent.add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.anchor_bottom = 0.0
	margin.offset_left = 12
	margin.offset_top = 12
	margin.offset_right = -12
	margin.offset_bottom = 0
	margin.theme = theme
	layer.add_child(margin)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "HudGlass"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)
	var col := vbox(Tokens.S1)
	panel.add_child(col)
	return {"layer": layer, "column": col, "panel": panel, "margin": margin}
