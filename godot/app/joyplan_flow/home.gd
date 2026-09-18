extends Control
## Usable home: 示例户型 / 相册导入 / 拍照. Never a blank single-pill void.
## Gallery is opt-in (Chinese OEM pickers often fail silently).

const GOLD := "res://fixtures/apt-plan-user-01.png"
const MediaPickerScript := preload("res://app/media_picker.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")

var _picker: Node
var _snack: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_HOME
	_build_chrome()
	_picker = MediaPickerScript.new()
	_picker.image_ready.connect(_on_image)
	_picker.failed.connect(_on_fail)
	_picker.cancelled.connect(_on_cancel)
	add_child(_picker)
	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.anchor_top = 1.0
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -88
	_snack.offset_bottom = -28
	add_child(_snack)
	Session.log_line.connect(func(t: String): _toast(t))


func _build_chrome() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.96, 0.93, 0.94)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_top", 36)
	pad.add_theme_constant_override("margin_bottom", 28)
	scroll.add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	pad.add_child(col)

	var brand := Studio.display("拓间")
	brand.add_theme_font_size_override("font_size", Tokens.FONT_DISPLAY)
	col.add_child(brand)
	var sub := Studio.caption("从户型图开始 · 示例可离线打开")
	col.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	col.add_child(spacer)

	col.add_child(Studio.action_card(
		"示例户型",
		"内置样张，无需相册或相机权限",
		"图",
		func(): _open_sample()
	))
	col.add_child(Studio.action_card(
		"相册导入",
		"从系统相册选择一张户型图",
		"相",
		func(): _open_gallery()
	))
	col.add_child(Studio.action_card(
		"拍照",
		"拍摄户型图；不可用时留在首页",
		"摄",
		func(): _open_camera()
	))

	var recents := PanelContainer.new()
	recents.add_theme_stylebox_override("panel", FlowIslands.frost(Tokens.PAGE_ISLAND, 18))
	recents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rec_col := VBoxContainer.new()
	rec_col.add_theme_constant_override("separation", 6)
	var rec_title := Studio.label("最近方案", Tokens.FONT_SECTION, Tokens.TEXT)
	rec_col.add_child(rec_title)
	var rec_empty := Studio.caption("还没有方案。先打开示例户型，或从相册导入。")
	rec_col.add_child(rec_empty)
	recents.add_child(rec_col)
	col.add_child(recents)


func _open_sample() -> void:
	var stored := Session.load_gold_sample()
	if stored.is_empty():
		_toast("无法打开示例户型图")
		return
	FlowRouter.scale(self)


func _open_gallery() -> void:
	_picker.pick_gallery()


func _open_camera() -> void:
	if OS.get_name() == "Android" and not _picker.available_on_android():
		_toast("当前设备没有可用相机插件")
		return
	_picker.capture_photo()


func _on_image(path: String) -> void:
	var stored := Session.store_imported_image(path)
	if stored.is_empty() and Session.last_error != "":
		_toast(Session.last_error)
		return
	if stored.is_empty():
		_toast("没有收到照片")
		return
	FlowRouter.scale(self)


func _on_fail(msg: String) -> void:
	_toast(msg if not msg.is_empty() else "打开相机或相册失败")


func _on_cancel() -> void:
	pass


func _toast(text: String) -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)
