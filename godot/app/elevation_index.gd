extends Control
## S8 Elevation Index stub (P1). Dark canvas + island chrome; no SceneIR writes.

const PageIslands := preload("res://app/ui/page_islands.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Color("1A1C20")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var top := PanelContainer.new()
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.16, 0.17, 0.20, 0.94)
	ts.set_corner_radius_all(Tokens.R_PILL)
	ts.content_margin_left = 10
	ts.content_margin_right = 10
	ts.content_margin_top = 6
	ts.content_margin_bottom = 6
	ts.shadow_color = Color(0, 0, 0, 0.35)
	ts.shadow_size = 10
	top.add_theme_stylebox_override("panel", ts)
	top.set_anchors_preset(PRESET_TOP_WIDE)
	top.anchor_bottom = 0.0
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 16
	top.offset_bottom = 64
	var row := Studio.hbox(8)
	row.add_child(PageIslands.circle_btn("↓", func(): Session.auto_save(), 36, Color(0.22, 0.23, 0.26), Color.WHITE))
	row.add_child(PageIslands.circle_btn("↶", func(): Session._log("撤销 P1"), 36, Color(0.22, 0.23, 0.26), Color.WHITE))
	row.add_child(PageIslands.circle_btn("↷", func(): Session._log("重做 P1"), 36, Color(0.22, 0.23, 0.26), Color.WHITE))
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)
	var mode := Studio.segmented(PackedStringArray(["All", "Elevation"]), 1, func(_i: int, _n: String): pass)
	row.add_child(mode)
	top.add_child(row)
	add_child(top)

	var toast := PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.12, 0.13, 0.16, 0.92)
	tsb.set_corner_radius_all(Tokens.R_PILL)
	tsb.content_margin_left = 18
	tsb.content_margin_right = 18
	tsb.content_margin_top = 10
	tsb.content_margin_bottom = 10
	toast.add_theme_stylebox_override("panel", tsb)
	toast.set_anchors_preset(PRESET_CENTER_TOP)
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -90
	toast.offset_right = 90
	toast.offset_top = 80
	toast.offset_bottom = 120
	toast.add_child(Studio.label("Elevation Index", Tokens.FONT_CHIP, Color.WHITE))
	add_child(toast)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.set_anchors_preset(PRESET_FULL_RECT)
	grid.offset_left = 20
	grid.offset_right = -20
	grid.offset_top = 140
	grid.offset_bottom = -96
	for i in 4:
		grid.add_child(_card("立面 %d" % (i + 1)))
	add_child(grid)

	var bottom := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.16, 0.17, 0.20, 0.94)
	bs.set_corner_radius_all(Tokens.R_PILL)
	bs.content_margin_left = 16
	bs.content_margin_right = 16
	bs.content_margin_top = 8
	bs.content_margin_bottom = 8
	bottom.add_theme_stylebox_override("panel", bs)
	bottom.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom.anchor_top = 1.0
	bottom.offset_left = 40
	bottom.offset_right = -40
	bottom.offset_top = -80
	bottom.offset_bottom = -20
	var brow := Studio.hbox(Tokens.S2)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_child(Studio.label("Annotation", Tokens.FONT_CHIP, Color.WHITE))
	brow.add_child(Studio.label("Draw", Tokens.FONT_CHIP, Color(1, 1, 1, 0.55)))
	bottom.add_child(brow)
	add_child(bottom)

	var back := PageIslands.circle_btn("‹", func():
		get_tree().change_scene_to_file("res://app/edit_3d.tscn")
	, 40, Tokens.PAGE_ISLAND)
	back.set_anchors_preset(PRESET_TOP_LEFT)
	back.offset_left = 12
	back.offset_top = 16
	back.offset_right = 52
	back.offset_bottom = 56
	add_child(back)

	Session._log("Elevation Index")


func _card(title: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 160)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.23, 0.26, 1)
	sb.set_corner_radius_all(Tokens.R_MD)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	var col := Studio.vbox(6)
	var preview := ColorRect.new()
	preview.color = Color(0.30, 0.32, 0.36, 1)
	preview.custom_minimum_size = Vector2(0, 100)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(preview)
	col.add_child(Studio.label(title, Tokens.FONT_CAPTION, Color(1, 1, 1, 0.8)))
	p.add_child(col)
	return p
