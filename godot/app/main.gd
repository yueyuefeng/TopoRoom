extends Control

const PlanCanvas := preload("res://app/plan_canvas.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")

var _home: Control
var _guide: Control
var _home_canvas: Control
var _guide_canvas: Control
var _scheme_list: VBoxContainer
var _typed: LineEdit
var _explicit: CheckBox
var _storey_h: LineEdit
var _snack: PanelContainer
var _home_phase: Label
var _guide_phase: Label
var _home_banner: Label
var _home_export: Label
var _guide_reason: Label
var _hero_meta: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Tokens.BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_home = _build_home()
	_guide = _build_guide()
	_guide.visible = false
	add_child(_home)
	add_child(_guide)

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.anchor_top = 1.0
	_snack.anchor_bottom = 1.0
	_snack.offset_left = Tokens.S2
	_snack.offset_right = -Tokens.S2
	_snack.offset_top = -132
	_snack.offset_bottom = -80
	add_child(_snack)

	Session.document_changed.connect(_render)
	Session.log_line.connect(_on_log)
	_render()


func _build_home() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.offset_bottom = -72
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", Tokens.S3)
	margin.add_theme_constant_override("margin_right", Tokens.S3)
	margin.add_theme_constant_override("margin_top", Tokens.S3)
	margin.add_theme_constant_override("margin_bottom", Tokens.S3)
	var col := Studio.vbox(Tokens.S2)
	margin.add_child(col)
	scroll.add_child(margin)
	root.add_child(scroll)

	var header := Studio.hbox(Tokens.S2)
	var brand := Studio.vbox(4)
	var title := Studio.display("拓间")
	brand.add_child(title)
	brand.add_child(Studio.caption("把现场户型图变成可改的方案"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	_home_phase = Studio.label("—", Tokens.FONT_CAPTION, Tokens.PRIMARY)
	header.add_child(_phase_wrap(_home_phase))
	col.add_child(header)

	_home_banner = Studio.caption("")
	_home_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_home_banner)

	var hero := Studio.card("HeroCard")
	var hero_col := Studio.vbox(Tokens.S1)
	var hero_top := Studio.hbox(Tokens.S2)
	_hero_meta = Studio.section("当前方案")
	_hero_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_top.add_child(_hero_meta)
	_home_export = Studio.label("", Tokens.FONT_CAPTION, Tokens.SUCCESS)
	hero_top.add_child(_home_export)
	hero_col.add_child(hero_top)
	_home_canvas = _canvas(220, false)
	hero_col.add_child(_home_canvas)
	hero_col.add_child(Studio.caption("暖色是承重墙，深灰是隔墙。图上的线来自方案，不是照片像素。"))
	hero.add_child(hero_col)
	col.add_child(hero)

	col.add_child(Studio.section("开始"))
	col.add_child(Studio.action_card("拍户型图", "打开相机，拍现场图后识别墙体", "拍", func(): _open_photo("camera")))
	col.add_child(Studio.action_card("从相册导入", "选一张已有户型图，接着预览识别", "图", func(): _open_photo("gallery")))
	col.add_child(Studio.action_card("引导量房", "一步步画墙、开门窗、记尺寸", "尺", func(): Session.screen = "guide"; _show_guide()))

	var more := Studio.card("QuietCard")
	var mcol := Studio.vbox(Tokens.S1)
	mcol.add_child(Studio.caption("也可以"))
	mcol.add_child(Studio.ghost("新建方案", func(): Session.new_scheme("doc_%d" % Time.get_ticks_msec()); _show_guide()))
	mcol.add_child(Studio.ghost("示例一室", func(): Session.fake_one_room(); _show_guide()))
	var extras := Studio.hbox(Tokens.S1)
	var ex := Studio.ghost("导出图档", func(): Session.export_deliverables())
	ex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ed := Studio.ghost("3D 编辑", func(): _open_edit_3d())
	ed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extras.add_child(ex)
	extras.add_child(ed)
	mcol.add_child(extras)
	var extras2 := Studio.hbox(Tokens.S1)
	var fx := Studio.ghost("加载夹具", func(): Session.load_fixture_json("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json"))
	fx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rm := Studio.ghost("漫游检查", func(): _open_roam())
	rm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extras2.add_child(fx)
	extras2.add_child(rm)
	mcol.add_child(extras2)
	more.add_child(mcol)
	col.add_child(more)

	col.add_child(Studio.section("方案"))
	_scheme_list = Studio.vbox(Tokens.S1)
	col.add_child(_scheme_list)

	var nav := Studio.nav_bar([
		{"glyph": "家", "title": "首页", "id": "home"},
		{"glyph": "尺", "title": "量房", "id": "guide"},
		{"glyph": "3D", "title": "空间", "id": "edit"},
	], 0, func(_i: int, item: Dictionary):
		var nid: String = str(item.get("id", ""))
		if nid == "guide":
			Session.screen = "guide"
			_show_guide()
		elif nid == "edit":
			_open_edit_3d()
	)
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.anchor_top = 1.0
	nav.offset_top = -72
	root.add_child(nav)
	return root


func _build_guide() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var top := MarginContainer.new()
	top.set_anchors_preset(PRESET_TOP_WIDE)
	top.anchor_bottom = 0.0
	top.offset_bottom = 76
	top.add_theme_constant_override("margin_left", Tokens.S2)
	top.add_theme_constant_override("margin_right", Tokens.S2)
	top.add_theme_constant_override("margin_top", Tokens.S2)
	var top_row := Studio.hbox(Tokens.S1)
	top_row.add_child(Studio.ghost("返回", func(): Session.screen = "home"; _show_home()))
	var gt := Studio.section("引导量房")
	gt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(gt)
	_guide_phase = Studio.label("—", Tokens.FONT_CAPTION, Tokens.PRIMARY)
	top_row.add_child(_phase_wrap(_guide_phase))
	top.add_child(top_row)
	root.add_child(top)

	var mid := MarginContainer.new()
	mid.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mid.offset_top = 76
	mid.offset_bottom = -280
	mid.add_theme_constant_override("margin_left", Tokens.S2)
	mid.add_theme_constant_override("margin_right", Tokens.S2)
	var hero := Studio.card("HeroCard")
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hcol := Studio.vbox(6)
	hcol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_guide_reason = Studio.caption("")
	hcol.add_child(_guide_reason)
	_guide_canvas = _canvas(160, true)
	_guide_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hcol.add_child(_guide_canvas)
	hero.add_child(hcol)
	mid.add_child(hero)
	root.add_child(mid)

	var dock := Studio.sheet()
	dock.set_anchors_preset(PRESET_BOTTOM_WIDE)
	dock.anchor_top = 1.0
	dock.offset_top = -272
	var dcol := Studio.vbox(Tokens.S1)
	dcol.add_child(Studio.caption("先画四墙，再开门窗，最后记尺寸。也可以一键走完示例。"))

	var primary := Studio.primary("一键引导量房", func(): Session.run_guided_edit())
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dcol.add_child(primary)

	var row1 := Studio.hbox(Tokens.S1)
	var w := Studio.ghost("画四墙", func(): Session.add_rectangle_walls())
	w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w.custom_minimum_size = Vector2(0, 44)
	var o := Studio.ghost("门 / 窗 / 垭口", func(): Session.add_opening("door"))
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	o.custom_minimum_size = Vector2(0, 44)
	row1.add_child(w)
	row1.add_child(o)
	dcol.add_child(row1)

	var row2 := Studio.hbox(Tokens.S1)
	for spec in [["窗洞", "window"], ["垭口", "archway"], ["闭合客厅", ""]]:
		var lab: String = spec[0]
		var kind: String = spec[1]
		var b: Button
		if kind.is_empty():
			b = Studio.ghost(lab, func(): Session.close_and_set_room())
		else:
			b = Studio.ghost(lab, func(): Session.add_opening(kind))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		row2.add_child(b)
	dcol.add_child(row2)

	var measure := Studio.hbox(Tokens.S1)
	_typed = LineEdit.new()
	_typed.text = "4000"
	_typed.placeholder_text = "边长 mm"
	_typed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_typed.custom_minimum_size = Vector2(0, 44)
	_explicit = CheckBox.new()
	_explicit.text = "已确认"
	_explicit.button_pressed = true
	measure.add_child(_typed)
	measure.add_child(_explicit)
	measure.add_child(Studio.ghost("记尺寸", func(): Session.measure_typed(_typed.text.to_float(), _explicit.button_pressed)))
	dcol.add_child(measure)

	var hrow := Studio.hbox(Tokens.S1)
	_storey_h = LineEdit.new()
	_storey_h.text = "2800"
	_storey_h.placeholder_text = "层高 mm"
	_storey_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_storey_h.custom_minimum_size = Vector2(0, 44)
	hrow.add_child(_storey_h)
	hrow.add_child(Studio.ghost("设层高", func(): Session.set_storey_height(_storey_h.text.to_float())))
	hrow.add_child(Studio.ghost("3D", func(): _open_edit_3d()))
	dcol.add_child(hrow)

	dock.add_child(dcol)
	root.add_child(dock)
	return root


func _phase_wrap(inner: Label) -> PanelContainer:
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
	p.size_flags_horizontal = Control.SIZE_SHRINK_END
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.autowrap_mode = TextServer.AUTOWRAP_OFF
	inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(inner)
	return p


func _canvas(min_h: int, expand: bool = false) -> Control:
	var c := PlanCanvas.new()
	c.custom_minimum_size = Vector2(0, min_h)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


func _show_home() -> void:
	_home.visible = true
	_guide.visible = false
	_render()


func _show_guide() -> void:
	Session.screen = "guide"
	_home.visible = false
	_guide.visible = true
	_render()


func _open_photo(intent: String) -> void:
	Session.photo_intent = intent
	get_tree().change_scene_to_file("res://app/photo_stub.tscn")


func _on_log(text: String) -> void:
	if _snack and _snack.has_method("show_message"):
		_snack.show_message(text)


func _open_roam() -> void:
	get_tree().change_scene_to_file("res://app/roam.tscn")


func _open_edit_3d() -> void:
	get_tree().change_scene_to_file("res://app/edit_3d.tscn")


func _scheme_row(path: String) -> Control:
	var row := Studio.card("QuietCard")
	var inner := Studio.hbox(Tokens.S2)
	var col := Studio.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(Studio.label(path.get_file(), Tokens.FONT_BODY, Tokens.TEXT))
	col.add_child(Studio.caption("保存在这台手机"))
	inner.add_child(col)
	inner.add_child(Studio.ghost("打开", func(): Session.load_scheme(path)))
	row.add_child(inner)
	return row


func _render() -> void:
	var json := Session.sceneir_json()
	if _home_canvas and _home_canvas.has_method("set_sceneir_json"):
		_home_canvas.set_sceneir_json(json)
	if _guide_canvas and _guide_canvas.has_method("set_sceneir_json"):
		_guide_canvas.set_sceneir_json(json)

	var core_ok := Session.has_core()
	var banner := "墙和尺寸写在方案里，界面只是看起来方便改。"
	if not core_ok:
		banner = "核心还没连上。按 README 编译一次就可以开始。"
	elif Session.glb_ok:
		banner = "已经可以去 3D 里看看。"
	_home_banner.text = banner

	var phase := Session.phase_label()
	_home_phase.text = phase
	_guide_phase.text = phase
	var doc: String = str(Session.host.document_id()) if core_ok else "—"
	_hero_meta.text = "方案  %s" % doc
	if Session.can_export():
		_home_export.text = "可导出"
		_home_export.add_theme_color_override("font_color", Tokens.SUCCESS)
	else:
		_home_export.text = Session.blocking_reason()
		_home_export.add_theme_color_override("font_color", Tokens.PRIMARY)
	if _guide_reason:
		_guide_reason.text = "可以导出了" if Session.can_export() else ("现在：%s" % Session.blocking_reason())

	for child in _scheme_list.get_children():
		child.queue_free()
	var schemes := Session.list_schemes()
	if schemes.is_empty():
		_scheme_list.add_child(Studio.caption("还没有保存的方案。拍一张图，或打开示例一室。"))
	else:
		for path in schemes:
			_scheme_list.add_child(_scheme_row(str(path)))

	if Session.screen == "guide" and _home.visible:
		_show_guide()


func apply_preview_json(text: String) -> void:
	if _home_canvas and _home_canvas.has_method("set_sceneir_json"):
		_home_canvas.set_sceneir_json(text)
	if _guide_canvas and _guide_canvas.has_method("set_sceneir_json"):
		_guide_canvas.set_sceneir_json(text)
