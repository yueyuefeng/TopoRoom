extends Control
## 工程项目: orange 新建项目 + quota banner + light capsule nav.

const Snackbar := preload("res://app/ui/snackbar.gd")
const JoyplanChrome := preload("res://app/joyplan_flow/joyplan_chrome.gd")

var _snack: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_PROJECTS
	_build()
	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_TOP_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = 64
	_snack.offset_bottom = 120
	add_child(_snack)


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("F7F7F7")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var tools := HBoxContainer.new()
	tools.set_anchors_preset(PRESET_TOP_RIGHT)
	tools.anchor_left = 1.0
	tools.offset_left = -120
	tools.offset_right = -16
	tools.offset_top = 18
	tools.offset_bottom = 58
	tools.add_child(JoyplanChrome.icon_btn("⌕", func(): _soon(), 40, Tokens.TEXT_SECONDARY))
	tools.add_child(JoyplanChrome.icon_btn("⋯", func(): _soon(), 40, Tokens.TEXT_SECONDARY))
	add_child(tools)

	var title := Studio.label("工程项目", 34, Tokens.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_TOP_WIDE)
	title.offset_top = 72
	title.offset_bottom = 122
	add_child(title)

	var plus := Button.new()
	plus.focus_mode = Control.FOCUS_NONE
	plus.set_anchors_preset(PRESET_CENTER_TOP)
	plus.anchor_left = 0.5
	plus.anchor_right = 0.5
	plus.offset_left = -92
	plus.offset_right = 92
	plus.offset_top = 150
	plus.offset_bottom = 334
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.JP_ORANGE
	sb.set_corner_radius_all(28)
	sb.shadow_color = Color(1.0, 0.42, 0.05, 0.35)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 8)
	var s2 := sb.duplicate()
	s2.bg_color = Tokens.JP_ORANGE_DEEP
	plus.add_theme_stylebox_override("normal", sb)
	plus.add_theme_stylebox_override("hover", s2)
	plus.add_theme_stylebox_override("pressed", s2)
	plus.pressed.connect(func(): FlowRouter.new_plan(self))
	add_child(plus)
	var plus_col := VBoxContainer.new()
	plus_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plus_col.alignment = BoxContainer.ALIGNMENT_CENTER
	plus_col.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var mark := Studio.label("+", 48, Color.WHITE)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap := Studio.label("新建项目", 18, Color.WHITE)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plus_col.add_child(mark)
	plus_col.add_child(cap)
	plus.add_child(plus_col)

	var banner := PanelContainer.new()
	var ban := StyleBoxFlat.new()
	ban.bg_color = Color("E8F6E9")
	ban.set_corner_radius_all(18)
	ban.content_margin_left = 16
	ban.content_margin_right = 16
	ban.content_margin_top = 14
	ban.content_margin_bottom = 14
	banner.add_theme_stylebox_override("panel", ban)
	banner.set_anchors_preset(PRESET_BOTTOM_WIDE)
	banner.offset_left = 22
	banner.offset_right = -22
	banner.offset_top = -188
	banner.offset_bottom = -112
	var bcol := VBoxContainer.new()
	bcol.add_theme_constant_override("separation", 4)
	var l1 := Studio.label("您还可以创建10个免费项目", 15, Tokens.TEXT)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var l2 := Studio.label("解锁无限项目数›", 14, Color("3D8A45"))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bcol.add_child(l1)
	bcol.add_child(l2)
	banner.add_child(bcol)
	add_child(banner)

	add_child(JoyplanChrome.bottom_nav(
		"projects",
		func(): FlowRouter.home(self),
		func(): pass,
		func(): _soon(),
		false
	))


func _soon(text: String = "即将支持") -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)
