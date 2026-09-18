extends PanelContainer
## S6 Ruler display sheet: white card, purple checks, Cancel/OK.

signal changed

const PageIslands := preload("res://app/ui/page_islands.gd")

var _list: VBoxContainer
var _items := [
	["柱", "column"],
	["管线", "plumbing"],
	["全选", "all"],
	["尺寸", "dims_3d"],
	["墙厚信息", "thickness"],
]


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
	var sheet := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 20
	sheet.add_theme_stylebox_override("panel", sb)
	var col := Studio.vbox(Tokens.S2)
	var head := Studio.hbox(Tokens.S1)
	var cancel := PageIslands.gray_btn("取消", func(): visible = false)
	head.add_child(cancel)
	var title := Studio.section("标尺显示")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	var ok := PageIslands.purple_btn("确定", func():
		changed.emit()
		visible = false
	)
	head.add_child(ok)
	col.add_child(head)
	_list = Studio.vbox(2)
	col.add_child(_list)
	sheet.add_child(col)
	wrap.add_child(sheet)


func present() -> void:
	_rebuild()
	visible = true
	move_to_front()


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for spec in _items:
		_row(str(spec[0]), str(spec[1]))


func _row(title: String, flag: String) -> void:
	var on := _flag_on(flag)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 44)
	var lab := Studio.label(title, Tokens.FONT_BODY, Tokens.TEXT)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	var mark := Studio.label("✓" if on else "", Tokens.FONT_TITLE, Tokens.PAGE_PURPLE)
	mark.custom_minimum_size = Vector2(28, 28)
	row.add_child(mark)
	row.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_toggle(flag)
	)
	_list.add_child(row)
	var sep := ColorRect.new()
	sep.color = Tokens.HAIRLINE
	sep.custom_minimum_size = Vector2(0, 1)
	_list.add_child(sep)


func _flag_on(flag: String) -> bool:
	if flag == "all":
		return Session.ruler_on("dims_3d") and Session.ruler_on("thickness") and Session.ruler_on("column") and Session.ruler_on("plumbing")
	return Session.ruler_on(flag)


func _toggle(flag: String) -> void:
	if flag == "all":
		var on := not _flag_on("all")
		for spec in _items:
			var f := str(spec[1])
			if f == "all":
				continue
			Session.set_ruler(f, on)
	else:
		Session.set_ruler(flag, not Session.ruler_on(flag))
	changed.emit()
	_rebuild()
