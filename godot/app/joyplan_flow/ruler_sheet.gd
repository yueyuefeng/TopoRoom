extends Control
## S6 — Ruler display sheet: Column / Plumbing / Select All / Dimensions / Thickness.

signal changed
signal dismissed

var _checks: Dictionary = {}
var _flags := [
	["Column", "column", "柱"],
	["Plumbing", "plumbing", "管线"],
	["Select All", "select_all", "全选"],
	["Dimensions", "dims_3d", "尺寸"],
	["Thickness information", "wall_len", "墙厚信息"],
]


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.09, 0.12, 0.35)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			visible = false
			dismissed.emit()
	)
	add_child(dim)
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", FlowIslands.white_sheet_style())
	sheet.set_anchors_preset(PRESET_BOTTOM_WIDE)
	sheet.anchor_top = 1.0
	sheet.offset_top = -420
	add_child(sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	sheet.add_child(col)
	var title := Studio.label("Ruler display", Tokens.FONT_SECTION, Tokens.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var zh := Studio.caption("尺规显示")
	zh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(zh)
	for spec in _flags:
		col.add_child(_row(str(spec[0]), str(spec[1]), str(spec[2])))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	var cancel := FlowIslands.gray_btn("Cancel", func(): visible = false; dismissed.emit())
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok := FlowIslands.purple_btn("OK", func(): _commit(); visible = false)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(cancel)
	actions.add_child(ok)
	col.add_child(actions)


func _row(en: String, flag: String, zh: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lab := Studio.label("%s  %s" % [en, zh], Tokens.FONT_BODY, Tokens.TEXT)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	var mark := Studio.label("✓" if Session.ruler_on(flag) or flag == "select_all" else "", Tokens.FONT_TITLE, Tokens.PAGE_PURPLE)
	mark.custom_minimum_size = Vector2(28, 28)
	_checks[flag] = mark
	var tap := Button.new()
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.set_anchors_preset(PRESET_FULL_RECT)
	tap.pressed.connect(func(): _toggle(flag))
	row.add_child(mark)
	row.add_child(tap)
	return row


func present() -> void:
	_refresh()
	visible = true
	move_to_front()


func _toggle(flag: String) -> void:
	if flag == "select_all":
		var on := not _all_on()
		for spec in _flags:
			var f := str(spec[1])
			if f == "select_all":
				continue
			Session.set_ruler(f, on)
		_refresh()
		changed.emit()
		return
	Session.set_ruler(flag, not Session.ruler_on(flag))
	_refresh()
	changed.emit()


func _all_on() -> bool:
	for spec in _flags:
		var f := str(spec[1])
		if f == "select_all":
			continue
		if not Session.ruler_on(f):
			return false
	return true


func _refresh() -> void:
	for spec in _flags:
		var f := str(spec[1])
		var mark: Label = _checks.get(f)
		if mark == null:
			continue
		var on := _all_on() if f == "select_all" else Session.ruler_on(f)
		mark.text = "✓" if on else ""


func _commit() -> void:
	changed.emit()
