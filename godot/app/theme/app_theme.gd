class_name AppTheme
extends Object
## Builds a Godot Theme from Tokens (StyleBoxFlat, CJK default font).


static func build(font: Font) -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = Tokens.FONT_BODY

	t.set_color("font_color", "Label", Tokens.TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_font("font", "Label", font)
	t.set_font_size("font_size", "Label", Tokens.FONT_BODY)
	t.set_constant("line_spacing", "Label", 4)

	_button(t, "Button", _fill(Tokens.SURFACE), _fill(Tokens.SURFACE_MUTED), _fill(Tokens.PRIMARY_SOFT), Tokens.TEXT)
	_button(t, "PrimaryButton", _fill(Tokens.PRIMARY), _fill(Tokens.PRIMARY_HOVER), _fill(Tokens.PRIMARY_HOVER), Tokens.TEXT_ON_ACCENT)
	t.set_type_variation("PrimaryButton", "Button")
	_button(t, "GhostButton", _outline(Tokens.SURFACE, Tokens.HAIRLINE), _outline(Tokens.SURFACE_MUTED, Tokens.PRIMARY), _fill(Tokens.PRIMARY_SOFT), Tokens.TEXT)
	t.set_type_variation("GhostButton", "Button")
	_button(t, "ChipButton", _chip(Tokens.SURFACE_MUTED), _chip(Tokens.PRIMARY_SOFT), _chip(Tokens.PRIMARY), Tokens.TEXT)
	t.set_type_variation("ChipButton", "Button")
	_button(t, "ChipOn", _chip(Tokens.PRIMARY), _chip(Tokens.PRIMARY_HOVER), _chip(Tokens.PRIMARY_HOVER), Tokens.TEXT_ON_ACCENT)
	t.set_type_variation("ChipOn", "Button")
	_button(t, "AccentChip", _chip(Tokens.PRIMARY), _chip(Tokens.PRIMARY_HOVER), _chip(Tokens.PRIMARY_HOVER), Tokens.TEXT_ON_ACCENT)
	t.set_type_variation("AccentChip", "Button")
	_button(t, "DangerChip", _chip(Tokens.DANGER_SOFT), _chip(Tokens.DANGER), _chip(Tokens.DANGER), Tokens.DANGER)
	t.set_type_variation("DangerChip", "Button")
	_button(t, "ActionCard", _action(Tokens.SURFACE_ELEVATED), _action(Tokens.PRIMARY_SOFT), _action(Tokens.PRIMARY_SOFT), Tokens.TEXT)
	t.set_type_variation("ActionCard", "Button")
	_button(t, "NavItem", _fill_tight(Color(0, 0, 0, 0)), _fill_tight(Tokens.SURFACE_MUTED), _fill_tight(Tokens.PRIMARY_SOFT), Tokens.TEXT_SECONDARY)
	t.set_type_variation("NavItem", "Button")
	_button(t, "NavItemOn", _fill_tight(Color(0, 0, 0, 0)), _fill_tight(Tokens.PRIMARY_SOFT), _fill_tight(Tokens.PRIMARY_SOFT), Tokens.PRIMARY)
	t.set_type_variation("NavItemOn", "Button")

	t.set_stylebox("panel", "PanelContainer", _card(Tokens.SURFACE, true))
	t.set_stylebox("panel", "Panel", _card(Tokens.SURFACE, false))
	t.set_type_variation("HeroCard", "PanelContainer")
	t.set_stylebox("panel", "HeroCard", _card(Tokens.SURFACE_ELEVATED, true))
	t.set_type_variation("QuietCard", "PanelContainer")
	t.set_stylebox("panel", "QuietCard", _card(Tokens.SURFACE_MUTED, false))
	t.set_type_variation("SheetPanel", "PanelContainer")
	t.set_stylebox("panel", "SheetPanel", _sheet())
	t.set_type_variation("NavBar", "PanelContainer")
	t.set_stylebox("panel", "NavBar", _nav())
	t.set_type_variation("HudGlass", "PanelContainer")
	t.set_stylebox("panel", "HudGlass", _hud())
	t.set_type_variation("SnackPanel", "PanelContainer")
	t.set_stylebox("panel", "SnackPanel", _snack(Tokens.TEXT))
	t.set_type_variation("SnackOk", "PanelContainer")
	t.set_stylebox("panel", "SnackOk", _snack(Tokens.SUCCESS))
	t.set_type_variation("SnackErr", "PanelContainer")
	t.set_stylebox("panel", "SnackErr", _snack(Tokens.DANGER))

	var le_bg := _outline(Tokens.SURFACE, Tokens.HAIRLINE)
	le_bg.content_margin_left = 14
	le_bg.content_margin_right = 14
	le_bg.content_margin_top = 10
	le_bg.content_margin_bottom = 10
	t.set_stylebox("normal", "LineEdit", le_bg)
	t.set_stylebox("focus", "LineEdit", _outline(Tokens.SURFACE, Tokens.PRIMARY))
	t.set_stylebox("read_only", "LineEdit", _outline(Tokens.SURFACE_MUTED, Tokens.HAIRLINE))
	t.set_color("font_color", "LineEdit", Tokens.TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Tokens.TEXT_DISABLED)
	t.set_color("caret_color", "LineEdit", Tokens.PRIMARY)
	t.set_font("font", "LineEdit", font)
	t.set_font_size("font_size", "LineEdit", Tokens.FONT_BODY)

	t.set_color("font_color", "CheckBox", Tokens.TEXT)
	t.set_color("font_hover_color", "CheckBox", Tokens.TEXT)
	t.set_color("font_pressed_color", "CheckBox", Tokens.PRIMARY)
	t.set_font("font", "CheckBox", font)
	t.set_font_size("font_size", "CheckBox", Tokens.FONT_CAPTION)

	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	t.set_constant("separation", "VBoxContainer", Tokens.S2)
	t.set_constant("separation", "HBoxContainer", Tokens.S1)
	t.set_constant("h_separation", "HFlowContainer", Tokens.S1)
	t.set_constant("v_separation", "HFlowContainer", Tokens.S1)

	var sep := StyleBoxFlat.new()
	sep.bg_color = Tokens.HAIRLINE
	sep.content_margin_top = 0
	sep.content_margin_bottom = 0
	t.set_stylebox("separator", "HSeparator", sep)
	return t


static func _button(t: Theme, type_name: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox, font_color: Color) -> void:
	t.set_stylebox("normal", type_name, normal)
	t.set_stylebox("hover", type_name, hover)
	t.set_stylebox("pressed", type_name, pressed)
	t.set_stylebox("disabled", type_name, _fill(Tokens.SURFACE_MUTED))
	t.set_stylebox("focus", type_name, hover)
	t.set_color("font_color", type_name, font_color)
	t.set_color("font_hover_color", type_name, font_color)
	t.set_color("font_pressed_color", type_name, font_color)
	t.set_color("font_disabled_color", type_name, Tokens.TEXT_DISABLED)
	t.set_color("font_focus_color", type_name, font_color)
	t.set_font_size("font_size", type_name, Tokens.FONT_BODY)
	t.set_constant("h_separation", type_name, 8)


static func _fill(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = Tokens.R_MD
	s.corner_radius_top_right = Tokens.R_MD
	s.corner_radius_bottom_left = Tokens.R_MD
	s.corner_radius_bottom_right = Tokens.R_MD
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.anti_aliasing = true
	return s


static func _fill_tight(bg: Color) -> StyleBoxFlat:
	var s := _fill(bg)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	s.corner_radius_top_left = Tokens.R_SM
	s.corner_radius_top_right = Tokens.R_SM
	s.corner_radius_bottom_left = Tokens.R_SM
	s.corner_radius_bottom_right = Tokens.R_SM
	return s


static func _outline(bg: Color, border: Color) -> StyleBoxFlat:
	var s := _fill(bg)
	s.border_color = border
	s.set_border_width_all(1)
	return s


static func _chip(bg: Color) -> StyleBoxFlat:
	var s := _fill(bg)
	s.corner_radius_top_left = Tokens.R_PILL
	s.corner_radius_top_right = Tokens.R_PILL
	s.corner_radius_bottom_left = Tokens.R_PILL
	s.corner_radius_bottom_right = Tokens.R_PILL
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func _action(bg: Color) -> StyleBoxFlat:
	var s := _card(bg, true)
	s.content_margin_left = Tokens.S2
	s.content_margin_right = Tokens.S2
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	return s


static func _card(bg: Color, elevated: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = Tokens.R_LG
	s.corner_radius_top_right = Tokens.R_LG
	s.corner_radius_bottom_left = Tokens.R_LG
	s.corner_radius_bottom_right = Tokens.R_LG
	s.content_margin_left = Tokens.S2
	s.content_margin_right = Tokens.S2
	s.content_margin_top = Tokens.S2
	s.content_margin_bottom = Tokens.S2
	s.border_color = Tokens.HAIRLINE
	s.set_border_width_all(1)
	s.anti_aliasing = true
	if elevated:
		s.shadow_color = Tokens.SHADOW
		s.shadow_size = 12
		s.shadow_offset = Vector2(0, 4)
	return s


static func _sheet() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Tokens.SURFACE_ELEVATED
	s.corner_radius_top_left = Tokens.R_XL
	s.corner_radius_top_right = Tokens.R_XL
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.content_margin_left = Tokens.S3
	s.content_margin_right = Tokens.S3
	s.content_margin_top = Tokens.S2
	s.content_margin_bottom = Tokens.S3
	s.border_color = Tokens.HAIRLINE
	s.border_width_top = 1
	s.anti_aliasing = true
	s.shadow_color = Tokens.SHADOW
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, -2)
	return s


static func _nav() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Tokens.SURFACE_ELEVATED
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.content_margin_left = Tokens.S2
	s.content_margin_right = Tokens.S2
	s.content_margin_top = 6
	s.content_margin_bottom = 10
	s.border_color = Tokens.HAIRLINE
	s.border_width_top = 1
	s.shadow_color = Tokens.SHADOW
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, -2)
	return s


static func _hud() -> StyleBoxFlat:
	var s := _card(Tokens.HUD_FILL, true)
	s.border_color = Tokens.HUD_BORDER
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.shadow_size = 8
	return s


static func _snack(accent: Color) -> StyleBoxFlat:
	var s := _card(Tokens.TEXT, true)
	s.bg_color = Tokens.TEXT
	s.border_color = accent
	s.border_width_left = 4
	s.border_width_top = 0
	s.border_width_right = 0
	s.border_width_bottom = 0
	s.corner_radius_top_left = Tokens.R_MD
	s.corner_radius_top_right = Tokens.R_MD
	s.corner_radius_bottom_left = Tokens.R_MD
	s.corner_radius_bottom_right = Tokens.R_MD
	s.shadow_size = 12
	return s
