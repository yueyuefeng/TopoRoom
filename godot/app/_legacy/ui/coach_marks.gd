extends PanelContainer
## First-run coach sequence. Visualization only; never writes SceneIR.

signal finished

var _steps: Array = []
var _index := 0
var _label: Label
var _next: Button


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_TOP_WIDE)
	anchor_bottom = 0.0
	offset_left = 16
	offset_right = -16
	offset_top = 72
	offset_bottom = 0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.20, 0.92)
	sb.set_corner_radius_all(Tokens.R_MD)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Tokens.SHADOW
	sb.shadow_size = 10
	add_theme_stylebox_override("panel", sb)
	var col := Studio.vbox(Tokens.S1)
	_label = Studio.label("", Tokens.FONT_BODY, Tokens.TEXT_ON_ACCENT, true)
	col.add_child(_label)
	var row := Studio.hbox(Tokens.S1)
	var skip := Button.new()
	skip.text = "跳过引导"
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_override("font", Studio.font)
	skip.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	skip.pressed.connect(_skip)
	row.add_child(skip)
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)
	_next = Button.new()
	_next.text = "下一步"
	_next.focus_mode = Control.FOCUS_NONE
	_next.add_theme_font_override("font", Studio.font)
	_next.add_theme_color_override("font_color", Tokens.TEXT_ON_ACCENT)
	_next.pressed.connect(_advance)
	row.add_child(_next)
	col.add_child(row)
	add_child(col)


func start(steps: Array) -> void:
	_steps = []
	for s in steps:
		if typeof(s) != TYPE_DICTIONARY:
			continue
		var id := str(s.get("id", ""))
		if id.is_empty() or Session.coach_done(id):
			continue
		_steps.append(s)
	_index = 0
	if _steps.is_empty():
		visible = false
		return
	_show_current()


func _show_current() -> void:
	if _index >= _steps.size():
		visible = false
		finished.emit()
		return
	var s: Dictionary = _steps[_index]
	_label.text = str(s.get("text", ""))
	_next.text = "完成" if _index == _steps.size() - 1 else "下一步"
	visible = true
	move_to_front()


func _advance() -> void:
	if _index < _steps.size():
		Session.mark_coach(str(_steps[_index].get("id", "")))
	_index += 1
	_show_current()


func _skip() -> void:
	for s in _steps:
		Session.mark_coach(str(s.get("id", "")))
	visible = false
	finished.emit()
