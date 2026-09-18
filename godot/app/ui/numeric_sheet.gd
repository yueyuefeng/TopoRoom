extends PanelContainer
## Numeric millimetre bottom sheet. Commits a single float; caller issues the command.

signal committed(value_mm: float)
signal cancelled

var _title: Label
var _edit: LineEdit
var _min := 10.0
var _max := 20000.0


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := StyleBoxFlat.new()
	dim.bg_color = Color(0.08, 0.09, 0.12, 0.42)
	add_theme_stylebox_override("panel", dim)
	var wrap := VBoxContainer.new()
	wrap.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	wrap.alignment = BoxContainer.ALIGNMENT_END
	add_child(wrap)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_STOP
	grow.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			dismiss()
	)
	wrap.add_child(grow)
	var sheet := Studio.sheet()
	var col := Studio.vbox(Tokens.S2)
	_title = Studio.section("输入尺寸")
	col.add_child(_title)
	var measure := Studio.hbox(Tokens.S1)
	_edit = LineEdit.new()
	_edit.placeholder_text = "毫米"
	_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit.custom_minimum_size = Vector2(0, 48)
	_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	measure.add_child(_edit)
	measure.add_child(Studio.label("mm", Tokens.FONT_BODY, Tokens.TEXT_SECONDARY))
	col.add_child(measure)
	col.add_child(Studio.primary("确定", func(): _commit()))
	col.add_child(Studio.ghost("取消", func(): dismiss()))
	sheet.add_child(col)
	wrap.add_child(sheet)


func present(title: String, value_mm: float, min_mm: float = 10.0, max_mm: float = 20000.0) -> void:
	_min = min_mm
	_max = max_mm
	_title.text = title
	_edit.text = str(int(round(value_mm)))
	visible = true
	move_to_front()
	_edit.grab_focus()
	_edit.select_all()


func dismiss() -> void:
	visible = false
	cancelled.emit()


func _commit() -> void:
	var v := _edit.text.strip_edges().to_float()
	if v < _min or v > _max:
		_title.text = "请输入 %d–%d mm" % [int(_min), int(_max)]
		return
	visible = false
	committed.emit(v)
