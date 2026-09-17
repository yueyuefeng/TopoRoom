extends Control
## 拍户型图：选图 → Fake 识墙 → 确认承重 → 拆改。像素不进 SceneIR。

const PlanCanvas := preload("res://app/plan_canvas.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")

var _mode := "pick"  # pick | review | demolish
var _canvas: Control
var _phase: Label
var _hint: Label
var _snack: PanelContainer
var _dock: VBoxContainer
var _confirm: PanelContainer
var _confirm_label: Label
var _pending: Callable
var _dialog: FileDialog
var _image_uri := ""


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
	root.add_theme_constant_override("separation", Tokens.S1)
	add_child(root)

	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", Tokens.S2)
	top.add_theme_constant_override("margin_right", Tokens.S2)
	top.add_theme_constant_override("margin_top", Tokens.S2)
	var top_row := Studio.hbox(Tokens.S1)
	top_row.add_child(Studio.ghost("返回", func(): _back()))
	var title := Studio.section("拍户型图")
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
	var hero := Studio.card("HeroCard")
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hcol := Studio.vbox(6)
	hcol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hint = Studio.caption("选择现场户型图或使用示例图。识别结果写入 SceneIR，照片网格不是尺寸真相。")
	hcol.add_child(_hint)
	_canvas = PlanCanvas.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.custom_minimum_size = Vector2(0, 280)
	_canvas.interactive = false
	_canvas.wall_clicked.connect(_on_wall_clicked)
	hcol.add_child(_canvas)
	hero.add_child(hcol)
	mid.add_child(hero)
	root.add_child(mid)

	var dock := PanelContainer.new()
	dock.theme_type_variation = "HeroCard"
	var dm := MarginContainer.new()
	dm.add_theme_constant_override("margin_left", Tokens.S2)
	dm.add_theme_constant_override("margin_right", Tokens.S2)
	dm.add_theme_constant_override("margin_top", 10)
	dm.add_theme_constant_override("margin_bottom", 10)
	_dock = Studio.vbox(Tokens.S1)
	dm.add_child(_dock)
	dock.add_child(dm)
	root.add_child(dock)

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.anchor_top = 1.0
	_snack.offset_left = Tokens.S2
	_snack.offset_right = -Tokens.S2
	# Sit above the bottom dock so 确认承重 / 拆改 chips stay tappable.
	_snack.offset_top = -220
	_snack.offset_bottom = -132
	add_child(_snack)
	Session.log_line.connect(func(text: String): _snack.show_message(text))
	Session.document_changed.connect(_refresh)

	_confirm = _build_confirm()
	add_child(_confirm)

	_dialog = FileDialog.new()
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg ; 户型图"])
	_dialog.title = "选择户型图"
	_dialog.file_selected.connect(_on_file)
	add_child(_dialog)

	_show_pick()


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
	dim.bg_color = Color(0.12, 0.1, 0.08, 0.45)
	overlay.add_theme_stylebox_override("panel", dim)
	var center := CenterContainer.new()
	overlay.add_child(center)
	var card := Studio.card("HeroCard")
	card.custom_minimum_size = Vector2(300, 0)
	var col := Studio.vbox(Tokens.S2)
	_confirm_label = Studio.label("承重墙拆除需要确认。", Tokens.FONT_BODY, Tokens.TEXT, true)
	col.add_child(_confirm_label)
	var row := Studio.hbox(Tokens.S1)
	row.add_child(Studio.ghost("取消", func(): overlay.visible = false))
	row.add_child(Studio.primary("确认拆除", func():
		overlay.visible = false
		if _pending.is_valid():
			_pending.call()
	))
	col.add_child(row)
	card.add_child(col)
	center.add_child(card)
	return overlay


func _clear_dock() -> void:
	for c in _dock.get_children():
		_dock.remove_child(c)
		c.queue_free()


func _show_pick() -> void:
	_mode = "pick"
	_phase.text = "导入"
	_hint.text = "选择现场户型图或使用示例图。识别走 FloorPlanVisionPort（当前 Fake），结果写入 SceneIR。"
	_canvas.interactive = false
	_canvas.selected_id = ""
	_clear_dock()
	_dock.add_child(Studio.primary("使用示例户型图", func(): _run_fake("fixture:photo")))
	var row := Studio.flow()
	row.add_child(Studio.ghost("从相册选择", func(): _pick_gallery()))
	row.add_child(Studio.ghost("拍照", func(): _pick_camera()))
	_dock.add_child(row)
	_dock.add_child(Studio.caption("Android 会打开系统文件/相机选择器；桌面为文件对话框。像素只作参考，墙段来自命令。"))
	_refresh()


func _show_review() -> void:
	_mode = "review"
	_phase.text = "确认承重"
	_hint.text = "点墙切换 承重/剪力墙（暖橙）与 非承重/砌体（深墨）。"
	_canvas.interactive = true
	_clear_dock()
	var flow := Studio.flow()
	flow.add_child(Studio.chip("标为承重", func(): _set_selected_kind("shearWall")))
	flow.add_child(Studio.chip("标为砌体", func(): _set_selected_kind("masonry")))
	flow.add_child(Studio.accent_chip("进入拆改", func(): _show_demolish()))
	_dock.add_child(flow)
	_refresh()


func _show_demolish() -> void:
	_mode = "demolish"
	_phase.text = "拆改"
	_hint.text = "点选墙段。砌体可直接拆；承重墙需确认。"
	_canvas.interactive = true
	_clear_dock()
	var flow := Studio.flow()
	flow.add_child(Studio.chip("整段拆除", func(): _act_demolish()))
	flow.add_child(Studio.chip("中点打断", func(): _act_split()))
	flow.add_child(Studio.chip("局部拆除", func(): _act_partial()))
	flow.add_child(Studio.chip("打门洞", func(): _act_punch()))
	flow.add_child(Studio.ghost("返回确认", func(): _show_review()))
	_dock.add_child(flow)
	_refresh()


func _back() -> void:
	if _mode == "demolish":
		_show_review()
		return
	if _mode == "review":
		_show_pick()
		return
	get_tree().change_scene_to_file("res://app/main.tscn")


func _run_fake(uri: String) -> void:
	_image_uri = uri
	Session.import_photo_fake(uri)
	if Session.last_error.is_empty():
		_show_review()
	_refresh()


func _pick_gallery() -> void:
	if OS.get_name() == "Android" and DisplayServer.has_method("file_dialog_show"):
		DisplayServer.file_dialog_show(
			"选择户型图",
			OS.get_system_dir(OS.SYSTEM_DIR_DCIM),
			"",
			false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
			PackedStringArray(["*.png,*.jpg,*.jpeg;Images"]),
			_on_native
		)
		return
	_dialog.popup_centered_ratio(0.8)


func _pick_camera() -> void:
	if OS.get_name() == "Android" and DisplayServer.has_method("file_dialog_show"):
		DisplayServer.file_dialog_show(
			"拍照或从相册选择",
			OS.get_system_dir(OS.SYSTEM_DIR_DCIM),
			"",
			false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
			PackedStringArray(["*.png,*.jpg,*.jpeg;Images"]),
			_on_native
		)
		return
	_snack.show_message("桌面请用文件对话框或示例户型图。", "info")
	_dialog.popup_centered_ratio(0.8)


func _on_native(status: bool, selected_paths: PackedStringArray, _filter: int) -> void:
	if status and not selected_paths.is_empty():
		_on_file(selected_paths[0])


func _on_file(path: String) -> void:
	_run_fake(path)


func _on_wall_clicked(wall_id: String) -> void:
	_canvas.selected_id = wall_id
	if _mode == "review":
		var kind: String = _wall_kind(wall_id)
		var next: String = "masonry" if kind == "shearWall" else "shearWall"
		Session.set_wall_kind(wall_id, next)
	_refresh()


func _set_selected_kind(kind: String) -> void:
	var id: String = str(_canvas.selected_id)
	if id.is_empty():
		_snack.show_message("请先点选一道墙。", "error")
		return
	Session.set_wall_kind(id, kind)


func _selected() -> String:
	return str(_canvas.selected_id)


func _needs_confirm(wall_id: String) -> bool:
	return _wall_kind(wall_id) == "shearWall"


func _with_force(fn: Callable) -> void:
	var id: String = _selected()
	if id.is_empty():
		_snack.show_message("请先点选一道墙。", "error")
		return
	if _needs_confirm(id):
		_confirm_label.text = "「%s」是承重/剪力墙。拆除或打断将改写 SceneIR，需确认。" % id
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
