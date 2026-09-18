extends Control
## JoyPlan home: hero interior + 2×2 cards + dark capsule nav. Never a blank pill.

const HERO := "res://fixtures/joyplan-home-hero.jpg"
const Snackbar := preload("res://app/ui/snackbar.gd")
const JoyplanChrome := preload("res://app/joyplan_flow/joyplan_chrome.gd")

var _snack: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_HOME
	_build()
	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_TOP_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = 24
	_snack.offset_bottom = 80
	add_child(_snack)
	Session.log_line.connect(func(t: String): _soon(t))


func _build() -> void:
	var hero := TextureRect.new()
	hero.set_anchors_preset(PRESET_TOP_WIDE)
	hero.anchor_bottom = 0.48
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.texture = _hero_texture()
	add_child(hero)

	var lower := ColorRect.new()
	lower.color = Color("D6D0C6")
	lower.set_anchors_preset(PRESET_FULL_RECT)
	lower.anchor_top = 0.46
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower)
	var dado := ColorRect.new()
	dado.color = Color("7EAA6C")
	dado.set_anchors_preset(PRESET_TOP_WIDE)
	dado.anchor_top = 0.46
	dado.offset_top = -22
	dado.offset_bottom = 6
	dado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dado)

	var pad := MarginContainer.new()
	pad.set_anchors_preset(PRESET_FULL_RECT)
	pad.anchor_top = 0.48
	pad.offset_bottom = -100
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 8)
	add_child(pad)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	pad.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.add_child(JoyplanChrome.color_btn("我的项目", Color(0.941, 0.769, 0.0, 0.94), Color.WHITE, func(): FlowRouter.projects(self), 1))
	top.add_child(JoyplanChrome.color_btn("AI厨房", Color(0.231, 0.478, 0.910, 0.94), Color.WHITE, func(): _soon("即将支持"), 1))
	col.add_child(top)

	var bot := HBoxContainer.new()
	bot.add_theme_constant_override("separation", 12)
	bot.custom_minimum_size = Vector2(0, 86)
	bot.add_child(JoyplanChrome.color_btn("AI设计", Color(0.22, 0.20, 0.18, 0.88), Color.WHITE, func(): _soon("即将支持"), 86))
	bot.add_child(JoyplanChrome.color_btn("拍照速记Pro", Color(0.22, 0.20, 0.18, 0.88), Color.WHITE, func(): _soon("即将支持"), 86))
	col.add_child(bot)

	add_child(JoyplanChrome.bottom_nav(
		"home",
		func(): pass,
		func(): FlowRouter.projects(self),
		func(): _soon("即将支持"),
		true
	))


func _hero_texture() -> Texture2D:
	var img := Image.new()
	var buf := FileAccess.get_file_as_bytes(HERO)
	if buf.is_empty() or img.load_jpg_from_buffer(buf) != OK:
		img = Image.create(720, 640, false, Image.FORMAT_RGB8)
		img.fill(Color("D8C8B8"))
		return ImageTexture.create_from_image(img)
	var w := img.get_width()
	var h := img.get_height()
	var top := int(h * 0.038)
	var crop_h := int(h * 0.40)
	img = img.get_region(Rect2i(0, top, w, maxi(crop_h, 8)))
	return ImageTexture.create_from_image(img)


func _soon(text: String = "即将支持") -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)
