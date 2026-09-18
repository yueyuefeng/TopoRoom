extends Control
## Boot: open the system photo picker immediately (JoyPlan frame_004).
## No dual-card camera/gallery home.

const MediaPickerScript := preload("res://app/media_picker.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")

var _picker: Node
var _snack: PanelContainer
var _cta: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_HOME
	var bg := ColorRect.new()
	bg.color = Color(0.95, 0.90, 0.91)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

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

	if _is_capture():
		return
	call_deferred("_open_gallery")


func _is_capture() -> bool:
	var n: Node = self
	while n:
		if str(n.name).begins_with("Capture"):
			return true
		n = n.get_parent()
	return false


func _open_gallery() -> void:
	_hide_cta()
	_picker.pick_gallery()


func _on_image(path: String) -> void:
	var stored := Session.store_imported_image(path)
	if stored.is_empty() and Session.last_error != "":
		_toast(Session.last_error)
		_show_cta()
		return
	FlowRouter.scale(self)


func _on_fail(msg: String) -> void:
	_toast(msg)
	_show_cta()


func _on_cancel() -> void:
	_show_cta()


func _show_cta() -> void:
	if _cta:
		_cta.visible = true
		return
	_cta = CenterContainer.new()
	_cta.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var b := FlowIslands.pill_btn("选择户型图", func(): _open_gallery(), 220)
	b.custom_minimum_size = Vector2(220, 48)
	_cta.add_child(b)
	add_child(_cta)


func _hide_cta() -> void:
	if _cta:
		_cta.visible = false


func _toast(text: String) -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)
