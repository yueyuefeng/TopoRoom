extends Control
## 拍户型图：系统相机 / 相册 → 立刻光栅识别 → 确认承重 → 3D / 拆改。

const PlanCanvas := preload("res://app/plan_canvas.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")
const MediaPickerScript := preload("res://app/media_picker.gd")
const ScaleCalibrate := preload("res://app/scale_calibrate.gd")
const OpeningLibrary := preload("res://app/opening_library.gd")

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
	top.add_child(top_row)
	root.add_child(top)

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

	_confirm = _build_confirm()
	add_child(_confirm)

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
	_confirm_label = Studio.label("这面墙标成了承重墙。拆除会改写方案，需要你点一次确认。", Tokens.FONT_BODY, Tokens.TEXT, true)
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
	_preview.visible = not _thumb_path.is_empty()
	if _preview.visible:
		_preview.custom_minimum_size = Vector2(0, 96)
	_canvas.visible = true
	_canvas.interactive = true
	_clear_dock()
	var row := Studio.hbox(Tokens.S1)
	var shear := Studio.ghost("标为承重", func(): _set_selected_kind("shearWall"))
	shear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shear.custom_minimum_size = Vector2(0, 48)
	var mason := Studio.ghost("标为隔墙", func(): _set_selected_kind("masonry"))
	mason.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mason.custom_minimum_size = Vector2(0, 48)
	row.add_child(shear)
	row.add_child(mason)
	_dock.add_child(row)
	_dock.add_child(_make_library())
	var next := Studio.primary("进入 3D", func(): _enter_3d())
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(next)
	var demolish := Studio.ghost("先拆改", func(): _show_demolish())
	demolish.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	demolish.custom_minimum_size = Vector2(0, 44)
	_dock.add_child(demolish)
	_refresh()


func _show_demolish() -> void:
	_mode = "demolish"
	_phase.text = "拆改"
	_hint.text = "点选墙段。隔墙可直接拆；承重墙会再问一次。"
	_canvas.interactive = true
	_canvas.visible = true
	_preview.visible = not _thumb_path.is_empty()
	_clear_dock()
	var row1 := Studio.hbox(Tokens.S1)
	var a := Studio.ghost("整段拆除", func(): _act_demolish())
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.custom_minimum_size = Vector2(0, 48)
	var b := Studio.ghost("中点打断", func(): _act_split())
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 48)
	row1.add_child(a)
	row1.add_child(b)
	_dock.add_child(row1)
	var row2 := Studio.hbox(Tokens.S1)
	var c := Studio.ghost("局部拆除", func(): _act_partial())
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size = Vector2(0, 48)
	var d := Studio.ghost("打门洞", func(): _act_punch())
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.custom_minimum_size = Vector2(0, 48)
	row2.add_child(c)
	row2.add_child(d)
	_dock.add_child(row2)
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
	lib.preview_ended.connect(func(): _canvas.clear_drop_preview())
	lib.dropped.connect(_on_library_drop)
	lib.tapped.connect(_on_library_tap)
	return lib


func _on_library_preview(kind: String, global_pos: Vector2) -> void:
	var local: Vector2 = _canvas.to_canvas(global_pos)
	_canvas.set_drop_preview(kind, local)


func _on_library_drop(kind: String, global_pos: Vector2) -> void:
	_canvas.clear_drop_preview()
	var local: Vector2 = _canvas.to_canvas(global_pos)
	var hit: Dictionary = _canvas.snap_opening(local, kind)
	if hit.is_empty() or str(hit.get("id", "")).is_empty():
		_snack.show_message("拖到墙上再松手。", "error")
		return
	Session.add_opening(kind, str(hit.get("id", "")), float(hit.get("offset_mm", 0)))
	_canvas.selected_id = str(hit.get("id", ""))
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
	if _mode == "review":
		var kind: String = _wall_kind(wall_id)
		var next: String = "masonry" if kind == "shearWall" else "shearWall"
		Session.set_wall_kind(wall_id, next)
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
		_confirm_label.text = "「%s」是承重墙。拆除或打断会改写方案，确认吗？" % id
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
