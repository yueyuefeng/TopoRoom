extends VBoxContainer
## Bottom-sheet door/window library: tabs 收藏/门/窗, tap or long-press drag + snap.

signal dropped(kind: String, global_pos: Vector2)
signal previewed(kind: String, global_pos: Vector2)
signal preview_ended
signal tapped(kind: String)

const LONG_MS := 0.38
const MOVE_CANCEL_PX := 14.0

var _tab := 0  # 0 favorite, 1 door, 2 window
var _kind := ""
var _press_pos := Vector2.ZERO
var _dragging := false
var _timer: Timer
var _ghost: PanelContainer
var _ghost_label: Label
var _layer: CanvasLayer
var _items: HBoxContainer
var _coach: PanelContainer
var _tabs: HBoxContainer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 118)
	_tabs = Studio.segmented(PackedStringArray(["收藏", "门", "窗"]), 0, func(i: int, _n: String):
		_tab = i
		_rebuild_items()
	)
	add_child(_tabs)
	add_child(Studio.caption("长按拖到墙上，或点选墙后轻点"))
	_items = Studio.hbox(Tokens.S1)
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
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = Tokens.R_MD
	sb.corner_radius_top_right = Tokens.R_MD
	sb.corner_radius_bottom_left = Tokens.R_MD
	sb.corner_radius_bottom_right = Tokens.R_MD
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
		return [["door", "门", Tokens.OPENING_DOOR, Tokens.SUCCESS_SOFT],
			["archway", "垭口", Tokens.OPENING_ARCH, Color(0.94, 0.90, 0.98)]]
	if _tab == 2:
		return [["window", "窗", Tokens.OPENING_WINDOW, Tokens.PRIMARY_SOFT]]
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
	sb.set_corner_radius_all(Tokens.R_MD)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_coach.add_theme_stylebox_override("panel", sb)
	var row := Studio.hbox(Tokens.S1)
	var lab := Studio.label("长按门或窗，拖到墙段上松手", Tokens.FONT_CAPTION, Tokens.TEXT_ON_ACCENT, true)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	row.add_child(Studio.ghost("知道了", func():
		Session.mark_coach("library")
		if _coach:
			_coach.visible = false
	))
	_coach.add_child(row)
	add_child(_coach)
	move_child(_coach, 0)


func _item(kind: String, title: String, ink: Color, fill: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 48)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.corner_radius_top_left = Tokens.R_MD
	sb.corner_radius_top_right = Tokens.R_MD
	sb.corner_radius_bottom_left = Tokens.R_MD
	sb.corner_radius_bottom_right = Tokens.R_MD
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var lab := Studio.label(title, Tokens.FONT_SECTION, ink)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(lab)
	p.gui_input.connect(func(ev: InputEvent): _on_item_input(kind, ev))
	return p


func _on_item_input(kind: String, ev: InputEvent) -> void:
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
