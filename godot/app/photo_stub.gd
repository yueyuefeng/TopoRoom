extends Control
## 拍户型图 S1–S4: 系统选图 → 校准 → 全屏 2D 岛式 chrome（无通栏 / 无 FAB）。

const PlanCanvas := preload("res://app/plan_canvas.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")
const MediaPickerScript := preload("res://app/media_picker.gd")
const ScaleCalibrate := preload("res://app/scale_calibrate.gd")
const OpeningLibrary := preload("res://app/opening_library.gd")
const NumericSheet := preload("res://app/ui/numeric_sheet.gd")
const RulerSheet := preload("res://app/ui/ruler_sheet.gd")
const CoachMarks := preload("res://app/ui/coach_marks.gd")
const PageIslands := preload("res://app/ui/page_islands.gd")
const Haptics := preload("res://app/ui/haptics.gd")

var _mode := "pick"  # pick | preview | calibrate | review | demolish
var _canvas: Control
var _preview: TextureRect
var _snack: PanelContainer
var _dock: VBoxContainer
var _dock_sheet: PanelContainer
var _confirm: PanelContainer
var _confirm_label: Label
var _pending: Callable
var _picker: Node
var _image_uri := ""
var _thumb_path := ""
var _calibrate: Control
var _readout: Label
var _readout_bar: Control
var _numeric: Control
var _ruler: Control
var _coach: Control
var _ctx: HBoxContainer
var _ctx_wrap: PanelContainer
var _lib_host: PanelContainer
var _bottom_dock: Control
var _snap_wall := ""
var _pending_dim: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Color.WHITE
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_canvas = PlanCanvas.new()
	_canvas.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_canvas.interactive = false
	_canvas.show_chrome = false
	_canvas.full_bleed = true
	_canvas.wall_clicked.connect(_on_wall_clicked)
	_canvas.opening_clicked.connect(_on_opening_clicked)
	add_child(_canvas)

	_preview = TextureRect.new()
	_preview.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.visible = false
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_preview)

	_mount_top()
	_mount_readout()
	_mount_ctx()
	_mount_bottom_dock()
	_mount_library()
	_mount_pick_dock()

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.anchor_top = 1.0
	_snack.offset_left = Tokens.S2
	_snack.offset_right = -Tokens.S2
	_snack.offset_top = -120
	_snack.offset_bottom = -72
	add_child(_snack)
	Session.log_line.connect(func(text: String): _snack.show_message(text))
	Session.document_changed.connect(_refresh)

	_confirm = _build_confirm()
	add_child(_confirm)
	_numeric = NumericSheet.new()
	add_child(_numeric)
	_ruler = RulerSheet.new()
	add_child(_ruler)
	_coach = CoachMarks.new()
	add_child(_coach)

	_picker = MediaPickerScript.new()
	add_child(_picker)
	_picker.image_ready.connect(_on_image)
	_picker.cancelled.connect(func(): _snack.show_message("已取消", "info"))
	_picker.failed.connect(func(msg: String): _snack.show_message(msg, "error"))
	resized.connect(_layout_library)

	_calibrate = ScaleCalibrate.new()
	_calibrate.visible = false
	_calibrate.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_calibrate.calibrated.connect(_on_calibrated)
	_calibrate.skipped.connect(func():
		_calibrate.visible = false
		_run_vision(_image_uri, 0.0)
	)
	add_child(_calibrate)

	_show_pick()
	var intent: String = Session.photo_intent
	Session.photo_intent = ""
	if intent == "camera":
		_pick_camera()
	elif intent == "gallery":
		_pick_gallery()
	elif Session.screen == "photo" and Session.has_core() and not Session.sceneir_json().is_empty():
		if not Session.last_import_path.is_empty():
			_thumb_path = Session.last_import_path
			_image_uri = Session.last_import_uri if not Session.last_import_uri.is_empty() else _thumb_path
			_load_thumb(_thumb_path)
		_show_review()


func _mount_top() -> void:
	add_child(PageIslands.top_bar(
		func(): _back(),
		PageIslands.view_toggle(true, func(): pass, func(): _enter_3d()),
		func(): _snack.show_message("多层楼层 P1")
	))


func _mount_readout() -> void:
	_readout_bar = PageIslands.readout_pill()
	_readout_bar.set_anchors_preset(PRESET_TOP_LEFT)
	_readout_bar.anchor_right = 0.0
	_readout_bar.anchor_bottom = 0.0
	_readout_bar.offset_left = 12
	_readout_bar.offset_top = 72
	_readout_bar.offset_right = 220
	_readout_bar.offset_bottom = 108
	_readout_bar.visible = false
	_readout = Studio.label("L  —   ∠  —", Tokens.FONT_CHIP, Tokens.TEXT)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_bar.add_child(_readout)
	_readout_bar.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_edit_dim("l")
	)
	add_child(_readout_bar)


func _mount_ctx() -> void:
	_ctx_wrap = PageIslands.readout_pill()
	_ctx_wrap.visible = false
	_ctx_wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	_ctx = Studio.hbox(4)
	_ctx_wrap.add_child(_ctx)
	add_child(_ctx_wrap)


func _mount_bottom_dock() -> void:
	_bottom_dock = PageIslands.bottom_2d_dock(
		func(): _enter_3d(),
		func(): _snack.show_message("已对准平面"),
		func():
			Session.auto_save()
			_snack.show_message("已保存", "ok")
	)
	_bottom_dock.visible = false
	add_child(_bottom_dock)


func _mount_library() -> void:
	_lib_host = PanelContainer.new()
	_lib_host.add_theme_stylebox_override("panel", PageIslands.white_sheet_style())
	_lib_host.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_lib_host.anchor_top = 1.0
	_lib_host.offset_top = -int(size.y * 0.34) if size.y > 1.0 else -360
	_lib_host.visible = false
	_lib_host.add_child(_make_library())
	add_child(_lib_host)


func _mount_pick_dock() -> void:
	_dock_sheet = PanelContainer.new()
	_dock_sheet.add_theme_stylebox_override("panel", PageIslands.white_sheet_style())
	_dock_sheet.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_dock_sheet.anchor_top = 1.0
	_dock_sheet.offset_top = -220
	var dm := MarginContainer.new()
	_dock = Studio.vbox(Tokens.S1)
	dm.add_child(_dock)
	_dock_sheet.add_child(dm)
	add_child(_dock_sheet)


func _coach_start(steps: Array) -> void:
	if _coach and _coach.has_method("start"):
		_coach.start(steps)


func _open_ruler() -> void:
	if _ruler and _ruler.has_method("present"):
		_ruler.present()


func _build_confirm() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.visible = false
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var dim := StyleBoxFlat.new()
	dim.bg_color = Color(0.08, 0.09, 0.12, 0.42)
	overlay.add_theme_stylebox_override("panel", dim)
	var wrap := VBoxContainer.new()
	wrap.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	wrap.alignment = BoxContainer.ALIGNMENT_END
	overlay.add_child(wrap)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_STOP
	grow.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			overlay.visible = false
	)
	wrap.add_child(grow)
	var sheet := Studio.sheet()
	var col := Studio.vbox(Tokens.S2)
	col.add_child(Studio.section("确认拆除承重墙"))
	_confirm_label = Studio.label("这面墙标成了承重墙。拆除会改写方案，需要你再点一次确认。", Tokens.FONT_BODY, Tokens.TEXT, true)
	col.add_child(_confirm_label)
	col.add_child(Studio.primary("确认拆除", func():
		overlay.visible = false
		if _pending.is_valid():
			_pending.call()
	))
	col.add_child(Studio.ghost("先不拆", func(): overlay.visible = false))
	sheet.add_child(col)
	wrap.add_child(sheet)
	return overlay


func _clear_dock() -> void:
	for c in _dock.get_children():
		_dock.remove_child(c)
		c.queue_free()


func _layout_library() -> void:
	if _lib_host == null:
		return
	var h := size.y
	if h <= 1.0:
		h = get_viewport_rect().size.y
	_lib_host.offset_top = -int(h * 0.34)


func _sync_islands() -> void:
	var editing := _mode == "review" or _mode == "demolish"
	if _bottom_dock:
		_bottom_dock.visible = editing
	if _lib_host:
		_lib_host.visible = editing
		_layout_library()
	if _dock_sheet:
		_dock_sheet.visible = _mode == "pick" or _mode == "preview"
	if _readout_bar:
		_readout_bar.visible = editing
	if _ctx_wrap and not editing:
		_ctx_wrap.visible = false


func _show_pick() -> void:
	_mode = "pick"
	_canvas.interactive = false
	_canvas.selected_id = ""
	_preview.visible = false
	_canvas.visible = true
	_clear_dock()
	var cam := Studio.primary("拍户型图", func(): _pick_camera())
	cam.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(cam)
	var gal := Studio.ghost("从相册导入", func(): _pick_gallery())
	gal.custom_minimum_size = Vector2(0, 48)
	gal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(gal)
	var demo := Studio.ghost("用示例图试试", func(): _run_example())
	demo.custom_minimum_size = Vector2(0, 44)
	demo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(demo)
	_dock.add_child(Studio.caption("相机会打开系统拍照；相册走系统选择器。"))
	_sync_islands()
	_refresh()


func _show_preview(path: String) -> void:
	_mode = "preview"
	_image_uri = path
	_thumb_path = path
	_load_thumb(path)
	_preview.visible = true
	_canvas.visible = false
	_clear_dock()
	var go := Studio.primary("开始识墙", func(): _run_vision(path))
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(go)
	var row := Studio.hbox(Tokens.S1)
	var recapture := Studio.ghost("重拍", func(): _pick_camera())
	recapture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reimport := Studio.ghost("重选", func(): _pick_gallery())
	reimport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(recapture)
	row.add_child(reimport)
	_dock.add_child(row)
	_sync_islands()


func _show_review() -> void:
	_mode = "review"
	_preview.visible = false
	_canvas.visible = true
	_canvas.interactive = true
	_sync_islands()
	_refresh()
	_coach_start([
		{"id": "review_walls", "text": "点墙切换承重和隔墙。顶栏切 3D，或点左下绿钮挤成立体。"},
		{"id": "library", "text": "长按底栏门或窗，拖到墙段上松手。"},
		{"id": "lwh", "text": "点左上 L / ∠ 读数，用数字底栏改毫米。"},
		{"id": "fab", "text": "顶栏 2D|3D 胶囊或底栏绿钮进入 3D。"},
	])


func _show_demolish() -> void:
	_mode = "demolish"
	_preview.visible = false
	_canvas.interactive = true
	_canvas.visible = true
	_sync_islands()
	_refresh()


func _back() -> void:
	if _mode == "demolish":
		_show_review()
		return
	if _mode == "review":
		if not _image_uri.is_empty() and not _image_uri.begins_with("fixture:"):
			_show_calibrate(_thumb_path if not _thumb_path.is_empty() else _image_uri)
			return
		_show_pick()
		return
	if _mode == "calibrate" or _mode == "preview":
		if _calibrate:
			_calibrate.visible = false
		_show_pick()
		return
	get_tree().change_scene_to_file("res://app/main.tscn")


func _run_fake(uri: String) -> void:
	_image_uri = uri
	Session.import_photo_fake(uri)
	if Session.last_error.is_empty():
		if not Session.last_import_path.is_empty():
			_thumb_path = Session.last_import_path
			_load_thumb(_thumb_path)
		_show_review()
	_refresh()


func _run_vision(uri: String, mm_per_px: float = 0.0) -> void:
	_image_uri = uri
	if _calibrate:
		_calibrate.visible = false
	Session.import_photo_vision(uri, mm_per_px)
	if Session.last_error.is_empty():
		if not Session.last_import_path.is_empty():
			_thumb_path = Session.last_import_path
			_load_thumb(_thumb_path)
		_show_review()
	_refresh()


func _run_example() -> void:
	var res_path := "res://fixtures/apt-plan-user-01.png"
	if FileAccess.file_exists(res_path):
		var stored: String = Session.store_imported_image(res_path)
		_show_calibrate(stored if not stored.is_empty() else ProjectSettings.globalize_path(res_path))
		return
	_run_fake("fixture:photo")


func _enter_3d() -> void:
	if _mode != "review" and _mode != "demolish":
		_snack.show_message("先完成识墙再进 3D")
		return
	Session.screen = "photo"
	Session.extrude_from_2d = true
	if is_instance_valid(_canvas):
		var tw := create_tween()
		if tw:
			tw.set_ease(Tween.EASE_IN)
			tw.set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(_canvas, "modulate:a", 0.15, 0.18)
			tw.tween_callback(func():
				get_tree().change_scene_to_file("res://app/edit_3d.tscn")
			)
			return
	get_tree().change_scene_to_file("res://app/edit_3d.tscn")


func _pick_gallery() -> void:
	_picker.pick_gallery()


func _pick_camera() -> void:
	_picker.capture_photo()


func _on_image(path: String) -> void:
	if path.is_empty():
		_snack.show_message("没有收到照片", "error")
		return
	var stored: String = Session.store_imported_image(path)
	if stored.is_empty():
		stored = path
	_thumb_path = stored
	_load_thumb(stored)
	_show_calibrate(stored)


func _show_calibrate(path: String) -> void:
	_mode = "calibrate"
	_image_uri = path
	_thumb_path = path
	_sync_islands()
	if _calibrate == null or not _calibrate.has_method("load_image"):
		_run_vision(path, 0.0)
		return
	if not _calibrate.load_image(path):
		_run_vision(path, 0.0)
		return
	_calibrate.visible = true
	_calibrate.move_to_front()
	_coach_start([
		{"id": "calibrate", "text": "把两个圆点拖到一条已知边上，输入真实毫米。拖动时看放大镜十字。"},
	])


func _on_calibrated(mm_per_px: float, _px: float, real_mm: float) -> void:
	_calibrate.visible = false
	_snack.show_message("比例 %d mm / %s" % [int(round(real_mm)), "边"], "ok")
	_run_vision(_image_uri, mm_per_px)


func _load_thumb(path: String) -> void:
	_thumb_path = path
	if path.is_empty() or path.begins_with("fixture:"):
		_preview.texture = null
		return
	var abs_path := path
	if path.begins_with("user://") or path.begins_with("res://"):
		abs_path = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return
	var img := Image.new()
	if img.load(abs_path) != OK:
		return
	_preview.texture = ImageTexture.create_from_image(img)


func _make_library() -> Control:
	var lib := OpeningLibrary.new()
	lib.previewed.connect(_on_library_preview)
	lib.preview_ended.connect(func():
		_snap_wall = ""
		_canvas.clear_drop_preview()
	)
	lib.dropped.connect(_on_library_drop)
	lib.tapped.connect(_on_library_tap)
	return lib


func _on_library_preview(kind: String, global_pos: Vector2) -> void:
	var local: Vector2 = _canvas.to_canvas(global_pos)
	var hit: Dictionary = _canvas.set_drop_preview(kind, local)
	var wid := str(hit.get("id", ""))
	if wid.is_empty():
		_snap_wall = ""
		return
	if wid != _snap_wall:
		_snap_wall = wid
		Haptics.snap()


func _on_library_drop(kind: String, global_pos: Vector2) -> void:
	_canvas.clear_drop_preview()
	var local: Vector2 = _canvas.to_canvas(global_pos)
	var hit: Dictionary = _canvas.snap_opening(local, kind)
	_snap_wall = ""
	if hit.is_empty() or str(hit.get("id", "")).is_empty():
		Haptics.warn()
		_snack.show_message("拖到墙上再松手。", "error")
		return
	Session.add_opening(kind, str(hit.get("id", "")), float(hit.get("offset_mm", 0)))
	_canvas.selected_id = str(hit.get("id", ""))
	Haptics.drop()
	_refresh()


func _on_library_tap(kind: String) -> void:
	var id: String = str(_canvas.selected_id)
	if id.is_empty():
		_snack.show_message("先点选一道墙，或长按拖到墙上。", "error")
		return
	var len: float = _wall_length(id)
	var width := 1200.0 if kind != "door" else 900.0
	var off := maxf((len - width) * 0.5, 50.0)
	Session.add_opening(kind, id, off)
	_refresh()


func _on_opening_clicked(opening_id: String, wall_id: String) -> void:
	_canvas.selected_opening_id = opening_id
	_canvas.selected_id = wall_id
	_refresh()


func _on_wall_clicked(wall_id: String) -> void:
	_canvas.selected_id = wall_id
	_canvas.selected_opening_id = ""
	_refresh()


func _set_selected_kind(kind: String) -> void:
	var id: String = str(_canvas.selected_id)
	if id.is_empty():
		_snack.show_message("先点选一道墙。", "error")
		return
	Session.set_wall_kind(id, kind)


func _selected() -> String:
	return str(_canvas.selected_id)


func _needs_confirm(wall_id: String) -> bool:
	return _wall_kind(wall_id) == "shearWall"


func _with_force(fn: Callable) -> void:
	var id: String = _selected()
	if id.is_empty():
		_snack.show_message("先点选一道墙。", "error")
		return
	if _needs_confirm(id):
		_confirm_label.text = "这面墙标成了承重墙。拆除会改写方案，需要你再点一次确认。"
		_pending = fn
		_confirm.visible = true
		return
	fn.call()


func _act_demolish() -> void:
	_with_force(func(): Session.demolish_wall(_selected(), true if _needs_confirm(_selected()) else false))


func _act_split() -> void:
	var id: String = _selected()
	var len: float = _wall_length(id)
	_with_force(func(): Session.split_wall(id, max(len * 0.5, 100.0)))


func _act_partial() -> void:
	var id: String = _selected()
	var len: float = _wall_length(id)
	var hole: float = minf(900.0, maxf(len * 0.3, 200.0))
	var off: float = maxf((len - hole) * 0.5, 50.0)
	_with_force(func(): Session.partial_demolish(id, off, hole, true if _needs_confirm(id) else false))


func _act_punch() -> void:
	var id: String = _selected()
	_with_force(func(): Session.punch_opening(id, "door", true if _needs_confirm(id) else false))


func _wall_kind(wall_id: String) -> String:
	for w in _walls():
		if str(w.get("id", "")) == wall_id:
			return str(w.get("kind", "masonry"))
	return ""


func _wall_length(wall_id: String) -> float:
	for w in _walls():
		if str(w.get("id", "")) != wall_id:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		return Vector2(float(b.get("x", 0)) - float(a.get("x", 0)), float(b.get("y", 0)) - float(a.get("y", 0))).length()
	return 0.0


func _walls() -> Array:
	var parsed: Variant = JSON.parse_string(Session.sceneir_json())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var storeys: Array = parsed.get("storeys", [])
	if storeys.is_empty() or typeof(storeys[0]) != TYPE_DICTIONARY:
		return []
	return storeys[0].get("walls", [])


func _refresh() -> void:
	if _canvas and _canvas.has_method("set_sceneir_json"):
		_canvas.set_sceneir_json(Session.sceneir_json())
	_refresh_selection()


func _refresh_selection() -> void:
	_rebuild_readout()
	_rebuild_ctx_pill()


func _rebuild_ctx_pill() -> void:
	if _ctx == null or not is_instance_valid(_ctx):
		return
	for c in _ctx.get_children():
		_ctx.remove_child(c)
		c.queue_free()
	if _mode != "review" and _mode != "demolish":
		_ctx_wrap.visible = false
		return
	var oid: String = str(_canvas.selected_opening_id) if _canvas else ""
	var wid: String = str(_canvas.selected_id) if _canvas else ""
	if oid.is_empty() and wid.is_empty():
		_ctx_wrap.visible = false
		return
	_ctx_wrap.visible = true
	if not oid.is_empty():
		_ctx_btn("设置", func(): _edit_dim("l"))
		_ctx_btn("翻转", func(): Session.flip_opening(oid))
		_ctx_btn("复制", func(): Session.duplicate_opening(oid))
		_ctx_btn("删除", func(): Session.delete_opening(oid))
	elif _mode == "review":
		_ctx_btn("承重", func(): _set_selected_kind("shearWall"))
		_ctx_btn("隔墙", func(): _set_selected_kind("masonry"))
		_ctx_btn("删除", func(): _act_demolish())
	else:
		_ctx_btn("整段拆除", func(): _act_demolish())
		_ctx_btn("打断", func(): _act_split())
		_ctx_btn("删除", func(): _act_partial())
	_place_ctx()


func _place_ctx() -> void:
	if _ctx_wrap == null or not _ctx_wrap.visible or _canvas == null:
		return
	var anchor: Vector2 = _canvas.selection_anchor()
	if anchor == Vector2.ZERO:
		_ctx_wrap.position = Vector2(24, 120)
		return
	var local: Vector2 = anchor - global_position + Vector2(-40, -52)
	_ctx_wrap.position = Vector2(
		clampf(local.x, 12.0, maxf(size.x - 220.0, 12.0)),
		clampf(local.y, 80.0, maxf(size.y - 320.0, 80.0))
	)


func _ctx_btn(text: String, cb: Callable) -> void:
	var b := Studio.chip(text, cb)
	b.custom_minimum_size = Vector2(0, 32)
	_ctx.add_child(b)


func _rebuild_readout() -> void:
	if _readout == null:
		return
	var editing := _mode == "review" or _mode == "demolish"
	_readout_bar.visible = editing
	if not editing:
		return
	var oid: String = str(_canvas.selected_opening_id) if _canvas else ""
	var wid: String = str(_canvas.selected_id) if _canvas else ""
	if not oid.is_empty():
		var dims: Dictionary = _lwh_dims()
		_readout.text = "L %d  W %d  H %d" % [
			int(round(float(dims.get("l", 0)))),
			int(round(float(dims.get("w", 0)))),
			int(round(float(dims.get("h", 0)))),
		]
		return
	if not wid.is_empty():
		var len := _wall_length(wid)
		var ang := 90.0
		if _canvas.has_method("wall_angle_deg"):
			ang = _canvas.wall_angle_deg(wid)
		_readout.text = "L %d   ∠ %d°" % [int(round(len)), int(round(ang))]
		return
	_readout.text = "L  —   ∠  —"


func _lwh_dims() -> Dictionary:
	var oid: String = str(_canvas.selected_opening_id) if _canvas else ""
	if not oid.is_empty():
		var op: Dictionary = Session.find_opening(oid)
		return {
			"l": float(op.get("width_mm", 0)),
			"w": float(op.get("thickness_mm", 200)),
			"h": float(op.get("height_mm", 0)),
			"opening": true,
			"id": oid,
		}
	var wid: String = str(_canvas.selected_id) if _canvas else ""
	var wall: Dictionary = Session.find_wall(wid)
	return {
		"l": float(wall.get("length_mm", 0)),
		"w": float(wall.get("thickness_mm", 200)),
		"h": float(wall.get("height_mm", 2800)),
		"opening": false,
		"id": wid,
	}


func _edit_dim(which: String) -> void:
	if _numeric == null:
		return
	var dims: Dictionary = _lwh_dims()
	if str(dims.get("id", "")).is_empty():
		return
	var titles_wall := {"l": "墙长", "w": "墙厚", "h": "墙高"}
	var titles_op := {"l": "洞口宽", "w": "墙厚", "h": "洞口高"}
	var titles: Dictionary = titles_op if bool(dims.get("opening", false)) else titles_wall
	var value := float(dims.get(which, 0))
	var min_mm := 80.0 if which == "w" else 200.0
	var max_mm := 800.0 if which == "w" else 20000.0
	if which == "h":
		min_mm = 400.0
		max_mm = 6000.0
	_numeric.present(str(titles.get(which, "尺寸")), value, min_mm, max_mm)
	if _numeric.committed.is_connected(_on_numeric_commit):
		_numeric.committed.disconnect(_on_numeric_commit)
	_pending_dim = {"which": which, "dims": dims}
	_numeric.committed.connect(_on_numeric_commit, CONNECT_ONE_SHOT)


func _on_numeric_commit(value_mm: float) -> void:
	var which := str(_pending_dim.get("which", ""))
	var dims: Dictionary = _pending_dim.get("dims", {})
	_pending_dim = {}
	if which.is_empty() or dims.is_empty():
		return
	var is_op := bool(dims.get("opening", false))
	var id := str(dims.get("id", ""))
	if is_op:
		var op: Dictionary = Session.find_opening(id)
		if op.is_empty():
			return
		if which == "w":
			Session.set_wall_thickness_mm(str(op.get("wall_id", "")), value_mm)
			return
		var width := value_mm if which == "l" else float(op.get("width_mm", 0))
		var height := value_mm if which == "h" else float(op.get("height_mm", 0))
		Session.update_opening_geom(
			id,
			str(op.get("kind", "door")),
			width,
			height,
			float(op.get("offset_mm", 0)),
			float(op.get("sill_mm", 0))
		)
		return
	if which == "l":
		Session.resize_wall_length(id, value_mm)
	elif which == "w":
		Session.set_wall_thickness_mm(id, value_mm)
	else:
		Session.set_wall_height_mm(id, value_mm)
