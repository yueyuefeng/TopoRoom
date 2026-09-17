extends Control

const PlanCanvas := preload("res://app/plan_canvas.gd")

var _home: Control
var _guide: Control
var _banner: Label
var _phase: Label
var _reason: Label
var _log: Label
var _home_canvas: Control
var _guide_canvas: Control
var _scheme_list: VBoxContainer
var _typed: LineEdit
var _explicit: CheckBox
var _storey_h: LineEdit
var _cjk: Font


func _ready() -> void:
	_cjk = _system_cjk()
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.98, 0.98, 0.97)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	_home = _build_home()
	_guide = _build_guide()
	_guide.visible = false
	add_child(_home)
	add_child(_guide)

	Session.document_changed.connect(_render)
	Session.log_line.connect(_on_log)
	_render()


func _system_cjk() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Noto Sans CJK SC",
		"Noto Sans CJK",
		"Source Han Sans SC",
		"DroidSansFallback",
		"Noto Sans SC",
		"WenQuanYi Micro Hei",
		"sans-serif",
	])
	return font


func _label(text: String, size_px: int = 16, color: Color = Color(0.15, 0.15, 0.15)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _cjk)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_override("font", _cjk)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	return b


func _scroll_col() -> Array:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(col)
	scroll.add_child(margin)
	root.add_child(scroll)
	return [root, col]


func _canvas() -> Control:
	var c := PlanCanvas.new()
	c.custom_minimum_size = Vector2(0, 280)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _build_home() -> Control:
	var pair: Array = _scroll_col()
	var root: Control = pair[0]
	var col: VBoxContainer = pair[1]
	col.add_child(_label("拓间 TopoRoom", 28, Color(0.12, 0.16, 0.14)))
	col.add_child(_label("Godot 宿主 · 户型图 · 量房会话 · 3D 编辑 · glb 只读漫游", 14, Color(0.35, 0.35, 0.32)))
	_banner = _label("")
	_phase = _label("")
	col.add_child(_banner)
	col.add_child(_phase)
	col.add_child(_btn("新建方案", func(): Session.new_scheme("doc_%d" % Time.get_ticks_msec()); _show_guide()))
	col.add_child(_btn("引导量房", func(): Session.screen = "guide"; _show_guide()))
	col.add_child(_btn("Fake 一室", func(): Session.fake_one_room(); _show_guide()))
	col.add_child(_btn("导出 DXF/PDF（glb 若 OK）", func(): Session.export_deliverables()))
	col.add_child(_view_row())
	col.add_child(_btn("加载夹具 垭口/净高", func(): Session.load_fixture_json("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json")))
	col.add_child(_label("方案列表", 18))
	_scheme_list = VBoxContainer.new()
	col.add_child(_scheme_list)
	_home_canvas = _canvas()
	col.add_child(_home_canvas)
	return root


func _build_guide() -> Control:
	var pair: Array = _scroll_col()
	var root: Control = pair[0]
	var col: VBoxContainer = pair[1]
	col.add_child(_label("引导量房", 26))
	col.add_child(_btn("返回首页", func(): Session.screen = "home"; _show_home()))
	_reason = _label("")
	col.add_child(_reason)
	col.add_child(_label("步骤：画墙 → 门窗洞/垭口 → 关键尺寸 → 闭合 → 导出", 14, Color(0.4, 0.4, 0.38)))
	col.add_child(_btn("1. 画矩形四墙 4000×3000", func(): Session.add_rectangle_walls()))
	col.add_child(_btn("2a. 门洞", func(): Session.add_opening("door")))
	col.add_child(_btn("2b. 窗洞", func(): Session.add_opening("window")))
	col.add_child(_btn("2c. 垭口", func(): Session.add_opening("archway")))
	col.add_child(_btn("3a. 关键边 Fake 激光", func(): Session.measure_laser_fake()))
	var row := HBoxContainer.new()
	_typed = LineEdit.new()
	_typed.text = "4000"
	_typed.placeholder_text = "手输 mm"
	_typed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_typed.add_theme_font_override("font", _cjk)
	_explicit = CheckBox.new()
	_explicit.text = "手输确认"
	_explicit.button_pressed = true
	_explicit.add_theme_font_override("font", _cjk)
	row.add_child(_typed)
	row.add_child(_explicit)
	col.add_child(row)
	col.add_child(_btn("3b. 关键边手输", func(): Session.measure_typed(_typed.text.to_float(), _explicit.button_pressed)))
	col.add_child(_btn("4. 闭合房间 + 客厅净高", func(): Session.close_and_set_room()))
	var hrow := HBoxContainer.new()
	_storey_h = LineEdit.new()
	_storey_h.text = "2800"
	_storey_h.placeholder_text = "层高 mm"
	_storey_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(_storey_h)
	hrow.add_child(_btn("设层高", func(): Session.set_storey_height(_storey_h.text.to_float())))
	col.add_child(hrow)
	col.add_child(_btn("放置梁（命令，非三角网）", func(): Session.place_hosted_beam()))
	col.add_child(_btn("一键引导工作流", func(): Session.run_guided_edit()))
	col.add_child(_btn("重建闸门探测", func(): _probe()))
	col.add_child(_btn("导出 DXF/PDF/glb", func(): Session.export_deliverables()))
	col.add_child(_view_row())
	_guide_canvas = _canvas()
	col.add_child(_guide_canvas)
	_log = _label("", 14, Color(0.25, 0.25, 0.25))
	col.add_child(_log)
	return root


func _show_home() -> void:
	_home.visible = true
	_guide.visible = false
	_render()


func _show_guide() -> void:
	Session.screen = "guide"
	_home.visible = false
	_guide.visible = true
	_render()


func _on_log(text: String) -> void:
	if _log:
		_log.text = text


func _probe() -> void:
	var d: Dictionary = Session.rebuild_probe()
	var msg := "StatusGate=%s" % str(d.get("status", "?"))
	if not d.get("ok", false):
		msg += "  %s" % str(d.get("error", ""))
	Session._log(msg)
	_render()


func _view_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var roam := _btn("漫游检查（只读 glb）", func(): _open_roam())
	roam.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edit := _btn("3D 编辑", func(): _open_edit_3d())
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(roam)
	row.add_child(edit)
	return row


func _open_roam() -> void:
	get_tree().change_scene_to_file("res://app/roam.tscn")


func _open_edit_3d() -> void:
	get_tree().change_scene_to_file("res://app/edit_3d.tscn")


func _scheme_button(path: String) -> Button:
	return _btn(path.get_file(), func(): Session.load_scheme(path))


func _render() -> void:
	var json := Session.sceneir_json()
	if _home_canvas and _home_canvas.has_method("set_sceneir_json"):
		_home_canvas.set_sceneir_json(json)
	if _guide_canvas and _guide_canvas.has_method("set_sceneir_json"):
		_guide_canvas.set_sceneir_json(json)

	var core_ok := Session.has_core()
	var banner := "Godot InteractionShell · SceneIR 唯一真相 · 3D 手柄经命令写回 · 网格禁止当尺寸"
	if not core_ok:
		banner = "GDExtension 未加载 — 先编译 libtoporoom.*.so（见 godot/README.md）"
	elif Session.glb_ok:
		banner += "  · glb OK"
	_banner.text = banner
	_phase.text = "阶段 %s    方案 %s" % [
		Session.phase_label(),
		Session.host.document_id() if core_ok else "—",
	]
	if _reason:
		var block := Session.blocking_reason()
		_reason.text = "可导出" if Session.can_export() else ("阻塞: %s" % block)

	for child in _scheme_list.get_children():
		child.queue_free()
	for path in Session.list_schemes():
		_scheme_list.add_child(_scheme_button(str(path)))

	if Session.screen == "guide" and _home.visible:
		_show_guide()
