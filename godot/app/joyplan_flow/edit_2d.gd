extends Control
## S3+S4 — 2D plan canvas + 2D|3D capsule + library sheet + contextual pill + 3-icon dock.

const PlanCanvas := preload("res://app/plan_canvas.gd")
const LibrarySheet := preload("res://app/joyplan_flow/library_sheet.gd")
const NumericSheet := preload("res://app/ui/numeric_sheet.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")
const Haptics := preload("res://app/ui/haptics.gd")

var _canvas: PlanCanvas
var _library: Control
var _readout: Label
var _readout_wrap: PanelContainer
var _ctx: Control
var _numeric: Control
var _snack: PanelContainer
var _pending_dim: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_EDIT_2D

	_canvas = PlanCanvas.new()
	_canvas.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_canvas.show_chrome = false
	_canvas.joyplan_look = true
	_canvas.interactive = true
	_canvas.wall_clicked.connect(_on_wall)
	_canvas.opening_clicked.connect(_on_opening)
	add_child(_canvas)

	add_child(FlowIslands.top_bar(
		func(): FlowRouter.home(self),
		FlowIslands.view_toggle(true, func(): pass, func(): _go_3d()),
		func(): pass
	))

	_readout_wrap = FlowIslands.readout_pill()
	_readout_wrap.set_anchors_preset(PRESET_TOP_LEFT)
	_readout_wrap.offset_left = 16
	_readout_wrap.offset_top = 72
	_readout_wrap.offset_right = 220
	_readout_wrap.offset_bottom = 112
	_readout = Studio.label("L  —    ∠  —", Tokens.FONT_CHIP, Tokens.TEXT)
	_readout.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_edit_dim("l")
	)
	_readout_wrap.add_child(_readout)
	add_child(_readout_wrap)

	add_child(FlowIslands.bottom_2d_dock(
		func(): _go_3d(),
		func(): _toggle_library(),
		func(): Session.export_deliverables()
	))

	var grab := Button.new()
	grab.name = "LibraryGrab"
	grab.text = "——  素材库"
	grab.focus_mode = Control.FOCUS_NONE
	grab.set_anchors_preset(PRESET_CENTER_BOTTOM)
	grab.anchor_left = 0.5
	grab.anchor_right = 0.5
	grab.offset_left = -70
	grab.offset_right = 70
	grab.offset_top = -118
	grab.offset_bottom = -90
	var empty := StyleBoxEmpty.new()
	grab.add_theme_stylebox_override("normal", empty)
	grab.add_theme_stylebox_override("hover", empty)
	grab.add_theme_stylebox_override("pressed", empty)
	grab.add_theme_font_override("font", Studio.font)
	grab.add_theme_font_size_override("font_size", 12)
	grab.add_theme_color_override("font_color", Tokens.TEXT_SECONDARY)
	grab.pressed.connect(_toggle_library)
	add_child(grab)

	_library = LibrarySheet.new()
	_library.visible = false
	_library.dropped.connect(_on_drop)
	_library.previewed.connect(_on_preview)
	_library.preview_ended.connect(func(): _canvas.clear_drop_preview())
	_library.tapped.connect(_on_tap_kind)
	add_child(_library)

	_numeric = NumericSheet.new()
	_numeric.committed.connect(_on_numeric)
	add_child(_numeric)

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -160
	_snack.offset_bottom = -110
	add_child(_snack)
	Session.log_line.connect(func(t: String): _snack.show_message(t))
	Session.document_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _canvas:
		_canvas.set_sceneir_json(Session.sceneir_json())
	_refresh_readout()
	_place_ctx()


func _toggle_library() -> void:
	show_library(not _library.visible)


func show_library(on: bool = true) -> void:
	_library.visible = on
	var grab := get_node_or_null("LibraryGrab")
	if grab:
		grab.visible = not on
	if on:
		_library.move_to_front()


func _go_3d() -> void:
	Session.extrude_from_2d = true
	FlowRouter.edit_3d(self)


func _on_wall(wall_id: String) -> void:
	_canvas.selected_id = wall_id
	_canvas.selected_opening_id = ""
	_refresh_readout()
	_place_ctx()


func _on_opening(oid: String, wall_id: String) -> void:
	_canvas.selected_opening_id = oid
	_canvas.selected_id = wall_id
	_refresh_readout()
	_place_ctx()


func _refresh_readout() -> void:
	if not _canvas.selected_opening_id.is_empty():
		var op: Dictionary = _canvas.opening_metrics(_canvas.selected_opening_id)
		var w: Dictionary = _canvas.wall_metrics(str(op.get("wall_id", _canvas.selected_id)))
		_readout.text = "L %d  W %d  H %d" % [
			int(round(float(op.get("width_mm", 0)))),
			int(round(float(w.get("thickness_mm", 200)))),
			int(round(float(op.get("height_mm", 2100)))),
		]
		return
	if not _canvas.selected_id.is_empty():
		var m: Dictionary = _canvas.wall_metrics(_canvas.selected_id)
		var wall: Dictionary = Session.find_wall(_canvas.selected_id)
		var a: Dictionary = wall.get("start", {})
		var b: Dictionary = wall.get("end", {})
		var ang := rad_to_deg(atan2(float(b.get("y", 0)) - float(a.get("y", 0)), float(b.get("x", 0)) - float(a.get("x", 0))))
		if ang < 0.0:
			ang += 360.0
		_readout.text = "L %d    ∠ %d°" % [int(round(float(m.get("length_mm", 0)))), int(round(ang))]
		return
	_readout.text = "L  —    ∠  —"


func _place_ctx() -> void:
	if _ctx:
		_ctx.queue_free()
		_ctx = null
	var actions: Array = []
	if not _canvas.selected_opening_id.is_empty():
		var oid: String = str(_canvas.selected_opening_id)
		actions = [
			["设置", func(): _edit_dim("l")],
			["翻转", func(): Session.flip_opening(oid); Haptics.snap()],
			["复制", func(): Session.duplicate_opening(oid); Haptics.snap()],
			["删除", func(): Session.delete_opening(oid)],
		]
	elif not _canvas.selected_id.is_empty():
		var wid: String = str(_canvas.selected_id)
		actions = [
			["设置", func(): _edit_dim("l")],
			["复制", func(): pass],
			["删除", func(): Session.demolish_wall(wid, Tokens.is_load_bearing_kind(str(_canvas.wall_metrics(wid).get("kind", ""))))],
		]
	else:
		return
	_ctx = FlowIslands.ctx_pill(actions)
	var anchor: Vector2 = _canvas.selected_anchor()
	_ctx.position = Vector2(clampf(anchor.x - 80.0, 12.0, size.x - 200.0), clampf(anchor.y - 56.0, 120.0, size.y - 180.0))
	add_child(_ctx)


func _edit_dim(which: String) -> void:
	var title := "长度 mm"
	var value := 900.0
	if not _canvas.selected_opening_id.is_empty():
		var op: Dictionary = _canvas.opening_metrics(_canvas.selected_opening_id)
		title = "洞口宽 mm" if which == "l" else "洞口高 mm"
		value = float(op.get("width_mm" if which == "l" else "height_mm", 900))
		_pending_dim = {"opening": true, "id": _canvas.selected_opening_id, "which": which}
	elif not _canvas.selected_id.is_empty():
		var m: Dictionary = _canvas.wall_metrics(_canvas.selected_id)
		title = "墙长 mm"
		value = float(m.get("length_mm", 0))
		_pending_dim = {"opening": false, "id": _canvas.selected_id, "which": which}
	else:
		return
	_numeric.present(title, value)


func _on_numeric(value_mm: float) -> void:
	var which := str(_pending_dim.get("which", "l"))
	if bool(_pending_dim.get("opening", false)):
		var op := Session.find_opening(str(_pending_dim.get("id", "")))
		if op.is_empty():
			return
		Session.update_opening_geom(
			str(op.get("id", "")),
			str(op.get("kind", "door")),
			value_mm if which == "l" else float(op.get("width_mm", 0)),
			value_mm if which == "h" else float(op.get("height_mm", 0)),
			float(op.get("offset_mm", 0)),
			float(op.get("sill_mm", 0))
		)
		return
	Session.resize_wall_length(str(_pending_dim.get("id", "")), value_mm)


func _on_drop(kind: String, global_pos: Vector2) -> void:
	var local: Vector2 = _canvas.to_canvas(global_pos)
	var hit: Dictionary = _canvas.snap_opening(local, kind)
	if hit.is_empty():
		_snack.show_message("拖到墙上再松手")
		return
	Session.add_opening(kind, str(hit.get("id", "")), float(hit.get("offset_mm", 0)))
	Haptics.drop()
	_canvas.clear_drop_preview()
	_library.visible = false


func _on_preview(kind: String, global_pos: Vector2) -> void:
	_canvas.set_drop_preview(kind, _canvas.to_canvas(global_pos))


func _on_tap_kind(kind: String) -> void:
	if _canvas.selected_id.is_empty():
		_snack.show_message("先点选一道墙，或长按拖到墙上")
		return
	var m: Dictionary = _canvas.wall_metrics(_canvas.selected_id)
	var width := 1200.0 if kind != "door" else 900.0
	var off := maxf((float(m.get("length_mm", 0)) - width) * 0.5, 50.0)
	Session.add_opening(kind, _canvas.selected_id, off)
