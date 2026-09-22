extends Control
## 新建户型 list. 导入户型图 opens 选择户型图; 自由绘制 opens the draw canvas.

const Snackbar := preload("res://app/ui/snackbar.gd")
const JoyplanChrome := preload("res://app/joyplan_flow/joyplan_chrome.gd")
const ImportPickHost := preload("res://app/joyplan_flow/import_pick_host.gd")

var _snack: PanelContainer
var _import: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_NEW_PLAN
	_build()
	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -96
	_snack.offset_bottom = -36
	add_child(_snack)
	_import = ImportPickHost.new()
	_import.imported.connect(_on_import_path)
	_import.failed.connect(_on_pick_fail)
	add_child(_import)


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("F7F7F7")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var head := HBoxContainer.new()
	head.set_anchors_preset(PRESET_TOP_WIDE)
	head.offset_left = 12
	head.offset_right = -12
	head.offset_top = 18
	head.offset_bottom = 64
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(44, 0)
	head.add_child(spacer)
	var title := Studio.label("新建户型", Tokens.FONT_TITLE, Tokens.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	head.add_child(JoyplanChrome.icon_btn("✕", func(): FlowRouter.projects(self), 44, Tokens.TEXT_SECONDARY))
	add_child(head)

	var pad := MarginContainer.new()
	pad.set_anchors_preset(PRESET_FULL_RECT)
	pad.offset_top = 72
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 18)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 24)
	add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	col.add_theme_constant_override("separation", 12)
	pad.add_child(col)

	var ar := PanelContainer.new()
	var ar_sb := StyleBoxFlat.new()
	ar_sb.bg_color = Color("EFEFEF")
	ar_sb.set_corner_radius_all(16)
	ar.add_theme_stylebox_override("panel", ar_sb)
	ar.custom_minimum_size = Vector2(0, 168)
	ar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ar_btn := Button.new()
	ar_btn.flat = true
	ar_btn.focus_mode = Control.FOCUS_NONE
	ar_btn.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ar_btn.pressed.connect(func(): _soon())
	ar.add_child(ar_btn)
	var ar_col := VBoxContainer.new()
	ar_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ar_col.alignment = BoxContainer.ALIGNMENT_CENTER
	ar_col.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var ar_g := Studio.label("▣", 36, Tokens.TEXT)
	ar_g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar_g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ar_t := Studio.label("AR扫描", Tokens.FONT_SECTION, Tokens.TEXT)
	ar_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar_t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ar_s := Studio.label("在房间内移动相机生成平面图", Tokens.FONT_CAPTION, Tokens.TEXT_SECONDARY)
	ar_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ar_s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ar_col.add_child(ar_g)
	ar_col.add_child(ar_t)
	ar_col.add_child(ar_s)
	ar.add_child(ar_col)
	col.add_child(ar)

	col.add_child(JoyplanChrome.list_row("自由绘制", "使用光标开始绘制新布局", "✎", func(): _open_draw()))
	col.add_child(JoyplanChrome.list_row("导入户型图", "导入户型图用于临摹绘制", "⇧", func(): _open_pick(), "新用户"))
	col.add_child(JoyplanChrome.list_row("手绘草图&房间", "手绘勾勒，户型立现", "✎", func(): _soon()))


func _open_draw() -> void:
	Session.start_free_draw(true)
	FlowRouter.free_draw(self)


func _open_pick() -> void:
	if _import:
		_import.open()


func _on_import_path(path: String) -> void:
	var stored := Session.store_imported_image(path)
	if stored.is_empty() and FileAccess.file_exists(path):
		Session.last_import_path = path
		Session.last_import_uri = path
		stored = path
	if stored.is_empty():
		_on_pick_fail(Session.last_error if Session.last_error != "" else "没有收到照片")
		return
	FlowRouter.scale(self)


func _on_pick_fail(msg: String) -> void:
	var text := msg if not msg.is_empty() else "打开相机或相册失败"
	_soon(text + " · 可改用示例户型")


func _soon(text: String = "即将支持") -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)
