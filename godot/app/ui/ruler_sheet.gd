extends PanelContainer
## Multi-toggle ruler / dimension display sheet.

signal changed

var _row: VBoxContainer


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
			visible = false
	)
	wrap.add_child(grow)
	var sheet := Studio.sheet()
	_row = Studio.vbox(Tokens.S1)
	_row.add_child(Studio.section("标尺显示"))
	_row.add_child(Studio.caption("只改显示，不写 SceneIR。"))
	sheet.add_child(_row)
	wrap.add_child(sheet)


func present() -> void:
	_rebuild()
	visible = true
	move_to_front()


func _rebuild() -> void:
	for c in _row.get_children():
		if c is Button or c is CheckBox:
			_row.remove_child(c)
			c.queue_free()
	_toggle("墙长", "wall_len")
	_toggle("房间面积 m²", "room_area")
	_toggle("门窗符号", "opening")
	_toggle("网格", "grid")
	_toggle("3D 尺寸", "dims_3d")
	_row.add_child(Studio.ghost("完成", func(): visible = false))


func _toggle(title: String, flag: String) -> void:
	var on := Session.ruler_on(flag)
	var b := Studio.chip(title, func():
		Session.set_ruler(flag, not Session.ruler_on(flag))
		changed.emit()
		_rebuild()
	, on)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.add_child(b)
