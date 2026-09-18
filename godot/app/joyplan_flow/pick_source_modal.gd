extends ColorRect
## 选择户型图: 相册选择 / 拍照上传 / 使用示例户型. Parent owns MediaPicker.

signal gallery_pressed
signal camera_pressed
signal sample_picked(path: String)
signal dismissed

const Snackbar := preload("res://app/ui/snackbar.gd")
const JoyplanChrome := preload("res://app/joyplan_flow/joyplan_chrome.gd")

var _snack: PanelContainer
var _card: PanelContainer
var busy := false


func _ready() -> void:
	color = Color(0.08, 0.08, 0.10, 0.46)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(func(ev: InputEvent):
		if busy:
			return
		if ev is InputEventMouseButton and ev.pressed:
			_close()
	)
	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -96
	_snack.offset_bottom = -36
	add_child(_snack)
	_build_card()


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", JoyplanChrome.fill(Color.WHITE, 22))
	_card.set_anchors_preset(PRESET_CENTER)
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left = -170
	_card.offset_right = 170
	_card.offset_top = -168
	_card.offset_bottom = 168
	_card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			accept_event()
	)
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	var title := Studio.label("选择户型图", Tokens.FONT_SECTION, Tokens.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(Control.new())
	head.add_child(title)
	head.add_child(JoyplanChrome.icon_btn("✕", func(): _close(), 36, Tokens.TEXT_SECONDARY))
	col.add_child(head)
	col.add_child(_action("相册选择", "从系统相册导入", func():
		busy = true
		gallery_pressed.emit()
	))
	col.add_child(_action("拍照上传", "拍摄户型图", func():
		busy = true
		camera_pressed.emit()
	))
	col.add_child(_action("使用示例户型", "无需相册或相机权限", func(): _use_sample(), Tokens.JP_ORANGE))
	_card.add_child(col)


func _action(title: String, subtitle: String, cb: Callable, ink: Color = Tokens.TEXT) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 64)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("F7F7F7")
	sb.set_corner_radius_all(14)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.pressed.connect(cb)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 14
	col.offset_right = -14
	col.offset_top = 8
	col.offset_bottom = -8
	var t := Studio.label(title, Tokens.FONT_SECTION, ink)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := Studio.label(subtitle, Tokens.FONT_CAPTION, Tokens.TEXT_SECONDARY)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.clip_text = true
	col.add_child(t)
	col.add_child(s)
	b.add_child(col)
	return b


func _use_sample() -> void:
	var stored := Session.load_gold_sample()
	if stored.is_empty():
		show_toast("无法打开示例户型图")
		return
	sample_picked.emit(stored)


func show_toast(text: String) -> void:
	busy = false
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)


func _close() -> void:
	if busy:
		return
	dismissed.emit()
	queue_free()
