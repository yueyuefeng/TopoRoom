extends Control
## S4 — bottom library sheet: tabs + grid + long-press drag onto the plan.

signal dropped(kind: String, global_pos: Vector2)
signal previewed(kind: String, global_pos: Vector2)
signal preview_ended
signal tapped(kind: String)

const LONG_MS := 0.38

var _tab := 1
var _grid: GridContainer
var _ghost: Control
var _ghost_kind := ""
var _press_kind := ""
var _press_t := 0.0
var _pressing := false
var _dragging := false
var _coach: PanelContainer
var _tabs: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_right = 0
	offset_top = -400
	offset_bottom = 0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := FlowIslands.white_sheet_style()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var grab := ColorRect.new()
	grab.custom_minimum_size = Vector2(36, 4)
	grab.color = Color(0.82, 0.82, 0.84)
	grab.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(grab)
	col.add_child(_tab_row())
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_grid)
	_coach = PanelContainer.new()
	var csb := FlowIslands.frost(Color(0.18, 0.48, 0.98, 1), Tokens.R_PILL)
	_coach.add_theme_stylebox_override("panel", csb)
	var cl := Studio.label("长按控件拖到平面图", Tokens.FONT_CAPTION, Color.WHITE)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coach.add_child(cl)
	col.add_child(_coach)
	if Session.coach_done("library"):
		_coach.visible = false
	_rebuild()
	set_process(true)


func _tab_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var names := ["收藏", "门", "窗", "梁管", "电气"]
	for i in names.size():
		var idx: int = i
		var b := Button.new()
		b.text = names[i]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", Studio.font)
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(func():
			_tab = idx
			_rebuild()
		)
		_tabs.append(b)
		row.add_child(b)
	return row


func _items() -> Array:
	if _tab == 0:
		var fav: Array = []
		for k in Session.favorite_kinds:
			fav.append(str(k))
		if fav.is_empty():
			return ["door", "window"]
		return fav
	if _tab == 1:
		return ["door", "archway"]
	if _tab == 2:
		return ["window"]
	if _tab == 3:
		return ["beam"]
	return ["outlet"]


func _rebuild() -> void:
	for i in _tabs.size():
		_tabs[i].button_pressed = i == _tab
		_tabs[i].add_theme_color_override("font_color", Tokens.TEXT if i == _tab else Tokens.TEXT_SECONDARY)
	for c in _grid.get_children():
		c.queue_free()
	for kind in _items():
		_grid.add_child(_cell(str(kind)))


func _cell(kind: String) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(72, 88)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.text = "%s\n%s" % [_glyph(kind), _label(kind)]
	b.add_theme_font_override("font", Studio.font)
	b.add_theme_font_size_override("font_size", 12)
	var n := FlowIslands.frost(Tokens.SURFACE_MUTED, 16)
	n.shadow_size = 0
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.gui_input.connect(func(ev: InputEvent): _on_cell(kind, ev, b))
	return b


func _glyph(kind: String) -> String:
	match kind:
		"door":
			return "▯"
		"window":
			return "▣"
		"archway":
			return "∩"
		"beam":
			return "━"
		"outlet":
			return "⊕"
		_:
			return "▢"


func _label(kind: String) -> String:
	match kind:
		"door":
			return "门"
		"window":
			return "窗"
		"archway":
			return "垭口"
		"beam":
			return "梁"
		"outlet":
			return "插座"
		_:
			return kind


func _on_cell(kind: String, ev: InputEvent, _b: Control) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_begin_press(kind)
		else:
			_end_press(kind)
	elif ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			_begin_press(kind)
		else:
			_end_press(kind)
	elif ev is InputEventMouseMotion and _pressing:
		if (ev as InputEventMouseMotion).relative.length() > 14.0 and _press_t < LONG_MS:
			_pressing = false
	elif ev is InputEventScreenDrag and _pressing:
		if (ev as InputEventScreenDrag).relative.length() > 14.0 and _press_t < LONG_MS:
			_pressing = false


func _begin_press(kind: String) -> void:
	_press_kind = kind
	_press_t = 0.0
	_pressing = true
	_dragging = false


func _end_press(kind: String) -> void:
	if _dragging:
		_drop()
		return
	if _pressing and _press_t < LONG_MS and kind == _press_kind:
		tapped.emit(kind)
	_pressing = false
	_press_kind = ""


func _process(dt: float) -> void:
	if _pressing and not _dragging:
		_press_t += dt
		if _press_t >= LONG_MS:
			_start_drag(_press_kind)
	if _dragging:
		_move_ghost(_pointer())


func _start_drag(kind: String) -> void:
	if kind == "beam" or kind == "outlet":
		_pressing = false
		return
	_dragging = true
	_ghost_kind = kind
	if _coach and not Session.coach_done("library"):
		Session.mark_coach("library")
		_coach.visible = false
	if _ghost:
		_ghost.queue_free()
	_ghost = PanelContainer.new()
	_ghost.add_theme_stylebox_override("panel", FlowIslands.frost())
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Studio.label(_label(kind), Tokens.FONT_CHIP, Tokens.TEXT)
	_ghost.add_child(l)
	var layer := CanvasLayer.new()
	layer.layer = 80
	layer.add_child(_ghost)
	get_tree().root.add_child(layer)
	_ghost.set_meta("layer", layer)
	_move_ghost(_pointer())


func _move_ghost(gp: Vector2) -> void:
	if _ghost == null:
		return
	_ghost.position = gp + Vector2(-28, -48)
	previewed.emit(_ghost_kind, gp)


func _drop() -> void:
	var gp := _pointer()
	var kind := _ghost_kind
	_clear_ghost()
	_dragging = false
	_pressing = false
	dropped.emit(kind, gp)
	preview_ended.emit()


func _clear_ghost() -> void:
	if _ghost == null:
		return
	var layer: Node = _ghost.get_meta("layer") if _ghost.has_meta("layer") else null
	_ghost.queue_free()
	_ghost = null
	if layer:
		layer.queue_free()
	_ghost_kind = ""


func _pointer() -> Vector2:
	return get_viewport().get_mouse_position()
