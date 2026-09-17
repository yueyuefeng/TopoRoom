extends PanelContainer
## Short-lived toast. Replaces the giant log Label.

signal dismissed

var _label: Label
var _timer: Timer


func _ready() -> void:
	theme_type_variation = "SnackPanel"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", Tokens.TEXT_ON_ACCENT)
	_label.add_theme_font_size_override("font_size", Tokens.FONT_CAPTION)
	if Studio and Studio.font:
		_label.add_theme_font_override("font", Studio.font)
	add_child(_label)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 3.4
	_timer.timeout.connect(_hide)
	add_child(_timer)


func show_message(text: String, kind: String = "info") -> void:
	if text.is_empty():
		return
	_label.text = text
	if kind == "error" or text.begins_with("错误") or text.contains("Fault"):
		theme_type_variation = "SnackErr"
	elif kind == "ok" or text.begins_with("Fake") or text.contains("完成") or text.contains("导出"):
		theme_type_variation = "SnackOk"
	else:
		theme_type_variation = "SnackPanel"
	visible = true
	modulate = Color(1, 1, 1, 1)
	_timer.start()


func _hide() -> void:
	visible = false
	dismissed.emit()
