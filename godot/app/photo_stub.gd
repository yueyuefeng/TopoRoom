extends Control
## 拍户型图：系统相机 / 相册 → 立刻光栅识别 → 确认承重 → 3D / 拆改。

const PlanCanvas := preload("res://app/plan_canvas.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")
const MediaPickerScript := preload("res://app/media_picker.gd")
const ScaleCalibrate := preload("res://app/scale_calibrate.gd")
const OpeningLibrary := preload("res://app/opening_library.gd")
const NumericSheet := preload("res://app/ui/numeric_sheet.gd")
const RulerSheet := preload("res://app/ui/ruler_sheet.gd")
const CoachMarks := preload("res://app/ui/coach_marks.gd")

var _mode := "pick"  # pick | preview | calibrate | review | demolish
var _canvas: Control
var _preview: TextureRect
var _phase: Label
var _hint: Label
var _snack: PanelContainer
var _dock: VBoxContainer
var _confirm: PanelContainer
var _confirm_label: Label
var _pending: Callable
var _picker: Node
var _image_uri := ""
var _thumb_path := ""
var _calibrate: Control
var _readout: Label
var _readout_bar: Control
var _lwh_row: HBoxContainer
var _numeric: Control
var _ruler: Control
var _coach: Control
var _ctx: HBoxContainer
var _fab: Button
var _fab_place_tries := 0
var _snap_wall := ""
const Haptics := preload("res://app/ui/haptics.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Tokens.BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", Tokens.S2)
	top.add_theme_constant_override("margin_right", Tokens.S2)
	top.add_theme_constant_override("margin_top", Tokens.S2)
	var top_row := Studio.hbox(Tokens.S1)
	top_row.add_child(Studio.ghost("返回", func(): _back()))
	var title := Studio.section("户型图")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)
	_phase = Studio.label("导入", Tokens.FONT_CAPTION, Tokens.PRIMARY)
	top_row.add_child(_pill(_phase))
	top_row.add_child(Studio.chip("标尺", func(): _open_ruler()))
	top.add_child(top_row)
	root.add_child(top)

	var read_m := MarginContainer.new()
	read_m.add_theme_constant_override("margin_left", Tokens.S2)
	read_m.add_theme_constant_override("margin_right", Tokens.S2)
	read_m.add_theme_constant_override("margin_top", 4)
	var read_panel := PanelContainer.new()
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Tokens.SURFACE
	rsb.corner_radius_top_left = Tokens.R_PILL
	rsb.corner_radius_top_right = Tokens.R_PILL
	rsb.corner_radius_bottom_left = Tokens.R_PILL
	rsb.corner_radius_bottom_right = Tokens.R_PILL
	rsb.content_margin_left = 16
	rsb.content_margin_right = 16
	rsb.content_margin_top = 8
	rsb.content_margin_bottom = 8
	read_panel.add_theme_stylebox_override("panel", rsb)
	_readout = Studio.label("点选墙或门窗，看长宽高", Tokens.FONT_SECTION, Tokens.TEXT)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var read_col := Studio.vbox(4)
	read_col.add_child(_readout)
	_lwh_row = Studio.hbox(Tokens.S1)
	_lwh_row.visible = false
	read_col.add_child(_lwh_row)
	read_panel.add_child(read_col)
	read_m.add_child(read_panel)
	root.add_child(read_m)
	_readout_bar = read_m
	_readout_bar.visible = false

	var mid := MarginContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("margin_left", Tokens.S2)
	mid.add_theme_constant_override("margin_right", Tokens.S2)
	mid.add_theme_constant_override("margin_top", Tokens.S1)
	mid.add_theme_constant_override("margin_bottom", Tokens.S1)
	var hero := Studio.card("HeroCard")
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hcol := Studio.vbox(8)
	hcol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hint = Studio.caption("拍一张户型图，或从相册选已有照片。识别结果会写成墙段，照片只作对照。")
	hcol.add_child(_hint)
	_preview = TextureRect.new()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.custom_minimum_size = Vector2(0, 180)
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.visible = false
	hcol.add_child(_preview)
	_canvas = PlanCanvas.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.custom_minimum_size = Vector2(0, 220)
	_canvas.interactive = false
	_canvas.wall_clicked.connect(_on_wall_clicked)
	_canvas.opening_clicked.connect(_on_opening_clicked)
	hcol.add_child(_canvas)
	hero.add_child(hcol)
	mid.add_child(hero)
	root.add_child(mid)

	var dock := Studio.sheet()
	var dm := MarginContainer.new()
	dm.add_theme_constant_override("margin_left", 0)
	dm.add_theme_constant_override("margin_right", 0)
	dm.add_theme_constant_override("margin_top", 4)
	dm.add_theme_constant_override("margin_bottom", 8)
	_dock = Studio.vbox(Tokens.S1)
	dm.add_child(_dock)
	dock.add_child(dm)
	root.add_child(dock)

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.anchor_top = 1.0
	_snack.offset_left = Tokens.S2
	_snack.offset_right = -Tokens.S2
	_snack.offset_top = -240
	_snack.offset_bottom = -148
	add_child(_snack)
	Session.log_line.connect(func(text: String): _snack.show_message(text))
	Session.document_changed.connect(_refresh)

	_fab = Studio.fab("3D", func(): _enter_3d())
	_fab.visible = false
	_fab.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	_fab.anchor_left = 1.0
	_fab.anchor_top = 1.0
	_fab.anchor_right = 1.0
	_fab.anchor_bottom = 1.0
	_fab.offset_left = -78
	_fab.offset_top = -268
	_fab.offset_right = -20
	_fab.offset_bottom = -210
	add_child(_fab)
	resized.connect(func(): _place_fab())

	_confirm = _build_confirm()
	add_child(_confirm)
	_confirm.visibility_changed.connect(_sync_fab)
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


func _coach_start(steps: Array) -> void:
	if _coach and _coach.has_method("start"):
		_coach.start(steps)


func _open_ruler() -> void:
	if _ruler and _ruler.has_method("present"):
		_ruler.present()


func _pill(inner: Label) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.PRIMARY_SOFT
	sb.corner_radius_top_left = Tokens.R_PILL
	sb.corner_radius_top_right = Tokens.R_PILL
	sb.corner_radius_bottom_left = Tokens.R_PILL
	sb.corner_radius_bottom_right = Tokens.R_PILL
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	inner.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(inner)
	return p


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


func _show_pick() -> void:
	_mode = "pick"
	_phase.text = "导入"
	_hint.text = "拍现场户型图，或从相册选一张。识别后可以改承重、再拆改。"
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
	_dock.add_child(Studio.caption("相机会打开系统拍照；相册走系统选择器。桌面试用时可改选本地图片。"))
	_refresh()


func _show_preview(path: String) -> void:
	_mode = "preview"
	_phase.text = "预览"
	_image_uri = path
	_thumb_path = path
	_load_thumb(path)
	_preview.visible = true
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.visible = false
	_hint.text = "确认这张图无误。识别会标出承重墙、砌体墙和门窗。"
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


func _show_review() -> void:
	_mode = "review"
	_phase.text = "确认承重"
	_hint.text = _review_hint()
	_preview.visible = false
	_preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_canvas.visible = true
	_canvas.interactive = true
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_clear_dock()
	_ctx = Studio.hbox(Tokens.S1)
	_dock.add_child(_ctx)
	_dock.add_child(_make_library())
	var next := Studio.primary("进入 3D", func(): _enter_3d())
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(next)
	var demolish := Studio.ghost("先拆改", func(): _show_demolish())
	demolish.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demolish.custom_minimum_size = Vector2(0, 44)
	_dock.add_child(demolish)
	_refresh()
	_coach_start([
		{"id": "review_walls", "text": "点墙切换承重（暖色）和隔墙（深灰）。认准了再进 3D。"},
		{"id": "library", "text": "长按底栏门或窗，拖到墙段上松手。收藏夹会记住常用构件。"},
		{"id": "lwh", "text": "点顶栏 L / W / H，用数字底栏改毫米。尺寸只经命令写回。"},
		{"id": "fab", "text": "点右下角 3D，平面会挤成立体。再点 2D 回来。"},
	])


func _show_demolish() -> void:
	_mode = "demolish"
	_phase.text = "拆改"
	_hint.text = "隔墙点选后直接拆。承重墙会弹出确认，避免误拆。"
	_preview.visible = false
	_preview.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_canvas.interactive = true
	_canvas.visible = true
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_clear_dock()
	_ctx = Studio.hbox(Tokens.S1)
	_dock.add_child(_ctx)
	_dock.add_child(_make_library())
	_dock.add_child(Studio.ghost("返回确认承重", func(): _show_review()))
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


func _review_hint() -> String:
	var v: Dictionary = Session.last_vision
	if v.is_empty():
		return "点墙切换承重（暖色）和隔墙（深灰）。认准了再进入 3D。"
	return "识别到承重 %d、砌体 %d、门 %d、窗 %d。点墙可改类型，然后进入 3D。" % [
		int(v.get("shear_count", 0)),
		int(v.get("masonry_count", 0)),
		int(v.get("door_count", 0)),
		int(v.get("window_count", 0)),
	]


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
	_phase.text = "标定"
	_image_uri = path
	_thumb_path = path
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
	if _readout:
		var show := _mode == "review" or _mode == "demolish"
		if _readout_bar:
			_readout_bar.visible = show
		_readout.visible = show
		_rebuild_lwh()
	_sync_fab()
	if _ctx == null or not is_instance_valid(_ctx):
		return
	if _mode != "review" and _mode != "demolish":
		return
	for c in _ctx.get_children():
		_ctx.remove_child(c)
		c.queue_free()
	var oid: String = str(_canvas.selected_opening_id) if _canvas else ""
	var wid: String = str(_canvas.selected_id) if _canvas else ""
	if oid.is_empty() and wid.is_empty():
		var hint := Studio.caption("点选墙或门窗，顶栏显示长宽高")
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_ctx.add_child(hint)
		return
	if not oid.is_empty():
		_ctx_btn("翻转", func(): Session.flip_opening(oid))
		_ctx_btn("旋转", func(): Session.rotate_opening(oid))
		_ctx_btn("复制", func(): Session.duplicate_opening(oid))
		_ctx_btn("删除", func(): Session.delete_opening(oid))
		return
	if _mode == "review":
		_ctx_btn("标为承重", func(): _set_selected_kind("shearWall"))
		_ctx_btn("标为隔墙", func(): _set_selected_kind("masonry"))
	else:
		_ctx_btn("整段拆除", func(): _act_demolish())
		_ctx_btn("中点打断", func(): _act_split())
		_ctx_btn("局部拆除", func(): _act_partial())
		_ctx_btn("打门洞", func(): _act_punch())


func _sync_fab() -> void:
	if _fab == null:
		return
	var overlay_up := _confirm != null and is_instance_valid(_confirm) and _confirm.visible
	_fab.visible = (_mode == "review" or _mode == "demolish") and not overlay_up
	if overlay_up:
		move_child(_confirm, get_child_count() - 1)
		return
	_fab_place_tries = 0
	call_deferred("_place_fab")


func _place_fab() -> void:
	if _fab == null or not _fab.visible or _dock == null:
		return
	if _dock.get_child_count() < 2:
		return
	var lib := _dock.get_child(1) as Control
	if lib == null or not is_instance_valid(lib):
		return
	if lib.size.y < 8.0:
		_fab_place_tries += 1
		if _fab_place_tries < 8:
			call_deferred("_place_fab")
		return
	_fab_place_tries = 0
	var view_h := size.y
	if view_h <= 1.0:
		view_h = get_viewport_rect().size.y
	var from_bottom := view_h - (lib.global_position.y + lib.size.y * 0.5)
	_fab.offset_right = -20.0
	_fab.offset_left = -78.0
	_fab.offset_bottom = -(from_bottom - 29.0)
	_fab.offset_top = _fab.offset_bottom - 58.0


func _ctx_btn(text: String, cb: Callable) -> void:
	var b := Studio.ghost(text, cb)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 48)
	_ctx.add_child(b)


func _rebuild_lwh() -> void:
	if _lwh_row == null or not is_instance_valid(_lwh_row):
		if _readout:
			_readout.text = "点选墙或门窗，点 L/W/H 改尺寸"
		return
	for c in _lwh_row.get_children():
		_lwh_row.remove_child(c)
		c.queue_free()
	var oid: String = str(_canvas.selected_opening_id) if _canvas else ""
	var wid: String = str(_canvas.selected_id) if _canvas else ""
	if oid.is_empty() and wid.is_empty():
		_readout.visible = true
		_readout.text = "点选墙或门窗，点 L/W/H 改尺寸"
		_lwh_row.visible = false
		return
	_readout.visible = false
	_lwh_row.visible = true
	var dims: Dictionary = _lwh_dims()
	_lwh_chip("L %d" % int(round(float(dims.get("l", 0)))), func(): _edit_dim("l"))
	_lwh_chip("W %d" % int(round(float(dims.get("w", 0)))), func(): _edit_dim("w"))
	_lwh_chip("H %d" % int(round(float(dims.get("h", 0)))), func(): _edit_dim("h"))


func _lwh_chip(text: String, cb: Callable) -> void:
	var b := Studio.chip(text, cb)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lwh_row.add_child(b)


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


var _pending_dim: Dictionary = {}


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

