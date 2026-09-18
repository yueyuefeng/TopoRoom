extends VBoxContainer
## S4 Bottom library sheet: tabs + grid, long-press drag, blue coach.

signal dropped(kind: String, global_pos: Vector2)
signal previewed(kind: String, global_pos: Vector2)
signal preview_ended
signal tapped(kind: String)

const LONG_MS := 0.38
const MOVE_CANCEL_PX := 14.0

var _tab := 0  # favorite, door, window, beam, electric
var _kind := ""
var _press_pos := Vector2.ZERO
var _dragging := false
var _timer: Timer
var _ghost: PanelContainer
var _ghost_label: Label
var _layer: CanvasLayer
var _items: GridContainer
var _coach: PanelContainer
var _tabs: HBoxContainer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 220)
	_tabs = Studio.segmented(PackedStringArray(["收藏", "门", "窗", "梁管", "电气"]), 0, func(i: int, _n: String):
		_tab = i
		_rebuild_items()
	)
	add_child(_tabs)
	_items = GridContainer.new()
	_items.columns = 4
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_theme_constant_override("h_separation", 8)
	_items.add_theme_constant_override("v_separation", 8)
	add_child(_items)
	_rebuild_items()
	_maybe_coach()

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = LONG_MS
	_timer.timeout.connect(_begin_drag)
	add_child(_timer)

	_layer = CanvasLayer.new()
	_layer.layer = 80
	add_child(_layer)
	_ghost = PanelContainer.new()
	_ghost.visible = false
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.SURFACE
	sb.border_color = Tokens.PRIMARY
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(Tokens.R_MD)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_ghost.add_theme_stylebox_override("panel", sb)
	_ghost_label = Studio.label("门洞", Tokens.FONT_SECTION, Tokens.PRIMARY)
	_ghost.add_child(_ghost_label)
	_layer.add_child(_ghost)


func _kinds_for_tab() -> Array:
	if _tab == 1:
		return [
			["door", "单开门", Tokens.OPENING_DOOR, Tokens.SUCCESS_SOFT],
			["door", "子母门", Tokens.OPENING_DOOR, Tokens.SUCCESS_SOFT],
			["archway", "垭口", Tokens.OPENING_ARCH, Color(0.94, 0.90, 0.98)],
			["door", "推拉门", Tokens.OPENING_DOOR, Tokens.SUCCESS_SOFT],
		]
	if _tab == 2:
		return [
			["window", "普通窗", Tokens.OPENING_WINDOW, Tokens.PRIMARY_SOFT],
			["window", "落地窗", Tokens.OPENING_WINDOW, Tokens.PRIMARY_SOFT],
			["window", "飘窗", Tokens.OPENING_WINDOW, Tokens.PRIMARY_SOFT],
			["window", "阳台", Tokens.OPENING_WINDOW, Tokens.PRIMARY_SOFT],
		]
	if _tab == 3:
		return [["beam", "梁", Tokens.TEXT_SECONDARY, Tokens.SURFACE_MUTED]]
	if _tab == 4:
		return [["electric", "插座", Tokens.TEXT_SECONDARY, Tokens.SURFACE_MUTED]]
	var fav: Array = []
	var seen := {}
	for k in Session.favorite_kinds:
		if seen.has(k):
			continue
		seen[k] = true
		fav.append(_kind_row(str(k)))
	if fav.is_empty():
		fav.append(_kind_row("door"))
		fav.append(_kind_row("window"))
	return fav


func _kind_row(kind: String) -> Array:
	if kind == "window":
		return ["window", "窗", Tokens.OPENING_WINDOW, Tokens.PRIMARY_SOFT]
	if kind == "archway":
		return ["archway", "垭口", Tokens.OPENING_ARCH, Color(0.94, 0.90, 0.98)]
	return ["door", "门", Tokens.OPENING_DOOR, Tokens.SUCCESS_SOFT]


func _rebuild_items() -> void:
	if _items == null:
		return
	for c in _items.get_children():
		_items.remove_child(c)
		c.queue_free()
	for row in _kinds_for_tab():
		_items.add_child(_item(str(row[0]), str(row[1]), row[2], row[3]))


func _maybe_coach() -> void:
	if Session.coach_done("library"):
		return
	_coach = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.PRIMARY
	sb.set_corner_radius_all(Tokens.R_PILL)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0.12, 0.25, 0.55, 0.28)
	sb.shadow_size = 10
	_coach.add_theme_stylebox_override("panel", sb)
	var row := Studio.hbox(Tokens.S1)
	var lab := Studio.label("长按控件拖到平面图", Tokens.FONT_CAPTION, Tokens.TEXT_ON_ACCENT, true)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	var skip := Button.new()
	skip.text = "知道了"
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_override("font", Studio.font)
	skip.add_theme_color_override("font_color", Tokens.TEXT_ON_ACCENT)
	skip.pressed.connect(func():
		Session.mark_coach("library")
		if _coach:
			_coach.visible = false
	)
	row.add_child(skip)
	_coach.add_child(row)
	add_child(_coach)


func _item(kind: String, title: String, ink: Color, fill: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 72)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(Tokens.R_MD)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var glyph := "门" if kind == "door" else ("窗" if kind == "window" else ("口" if kind == "archway" else "·"))
	var g := Studio.label(glyph, Tokens.FONT_TITLE, ink)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lab := Studio.label(title, Tokens.FONT_CAPTION, ink)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(g)
	col.add_child(lab)
	p.add_child(col)
	p.gui_input.connect(func(ev: InputEvent): _on_item_input(kind, ev))
	return p


func _on_item_input(kind: String, ev: InputEvent) -> void:
	if kind == "beam" or kind == "electric":
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			Session._log("梁管 / 电气为 P1")
		return
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_arm(kind, mb.global_position)
			accept_event()
		else:
			_release(mb.global_position)
			accept_event()
	elif ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			_arm(kind, st.position)
			accept_event()
		else:
			_release(st.position)
			accept_event()


func _arm(kind: String, pos: Vector2) -> void:
	_kind = kind
	_press_pos = pos
	_dragging = false
	_ghost_label.text = Tokens.opening_label(kind)
	_timer.start()


func _begin_drag() -> void:
	if _kind.is_empty():
		return
	_dragging = true
	_ghost.visible = true
	_place_ghost(get_global_mouse_position())
	previewed.emit(_kind, get_global_mouse_position())


func _place_ghost(global_pos: Vector2) -> void:
	_ghost.position = global_pos + Vector2(12, -48)


func _input(event: InputEvent) -> void:
	if _kind.is_empty():
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var pos: Vector2 = mm.global_position
		if _dragging:
			_place_ghost(pos)
			previewed.emit(_kind, pos)
		elif pos.distance_to(_press_pos) > MOVE_CANCEL_PX and _timer.time_left > 0.0:
			_timer.stop()
			_kind = ""
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _dragging:
			_place_ghost(sd.position)
			previewed.emit(_kind, sd.position)
		elif sd.position.distance_to(_press_pos) > MOVE_CANCEL_PX and _timer.time_left > 0.0:
			_timer.stop()
			_kind = ""
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_release(mb.global_position)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if not st.pressed:
			_release(st.position)


func _release(pos: Vector2) -> void:
	if _kind.is_empty():
		return
	var kind := _kind
	var was_drag := _dragging
	_timer.stop()
	_kind = ""
	_dragging = false
	_ghost.visible = false
	if was_drag:
		dropped.emit(kind, pos)
		preview_ended.emit()
	else:
		tapped.emit(kind)
	get_viewport().set_input_as_handled()
