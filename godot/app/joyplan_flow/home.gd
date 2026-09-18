extends Control
## S1 — minimal entry: 拍户型 / 相册. Floating islands only.

const MediaPickerScript := preload("res://app/media_picker.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")

var _picker: Node
var _snack: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_HOME
	var bg := ColorRect.new()
	bg.color = Color("F2F3F5")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_picker = MediaPickerScript.new()
	_picker.image_ready.connect(_on_image)
	_picker.failed.connect(_on_fail)
	_picker.cancelled.connect(func(): _toast("已取消"))
	add_child(_picker)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	col.offset_left = 28
	col.offset_right = -28
	col.offset_top = 96
	col.offset_bottom = -48
	col.add_theme_constant_override("separation", 18)
	add_child(col)

	var brand := Studio.display("拓间")
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(brand)
	var sub := Studio.caption("拍户型图，校准尺度，编辑平面与三维")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(Studio.spacer(24))

	col.add_child(_island_cta("拍户型", "打开系统相机", func(): _picker.capture_photo()))
	col.add_child(_island_cta("相册", "从相册导入户型图", func(): _picker.pick_gallery()))

	var example := FlowIslands.pill_btn("用示例图试试", func(): _example())
	example.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var wrap := CenterContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(example)
	col.add_child(wrap)

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.anchor_top = 1.0
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -88
	_snack.offset_bottom = -28
	add_child(_snack)
	Session.log_line.connect(func(t: String): _toast(t))


func _island_cta(title: String, subtitle: String, cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 88)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := FlowIslands.frost(Tokens.PAGE_ISLAND, 24)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(cb)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -8
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 4)
	var t := Studio.label(title, Tokens.FONT_TITLE, Tokens.TEXT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := Studio.caption(subtitle)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(t)
	texts.add_child(s)
	row.add_child(texts)
	row.add_child(Studio.label("›", 28, Tokens.TEXT_DISABLED))
	b.add_child(row)
	return b


func _example() -> void:
	var res := "res://fixtures/apt-plan-user-01.png"
	if not FileAccess.file_exists(res):
		_toast("缺少示例图")
		return
	var stored := Session.store_imported_image(ProjectSettings.globalize_path(res))
	if stored.is_empty():
		Session.last_import_path = ProjectSettings.globalize_path(res)
		Session.last_import_uri = Session.last_import_path
	FlowRouter.scale(self)


func _on_image(path: String) -> void:
	var stored := Session.store_imported_image(path)
	if stored.is_empty() and Session.last_error != "":
		_toast(Session.last_error)
		return
	FlowRouter.scale(self)


func _on_fail(msg: String) -> void:
	_toast(msg)


func _toast(text: String) -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)
