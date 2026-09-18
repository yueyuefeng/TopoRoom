extends Control
## S8 — Elevation Index stub (P1). Dark canvas + pill chrome.

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_ELEVATION
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.10)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var top := PanelContainer.new()
	var sb := FlowIslands.frost(Color(0.16, 0.16, 0.18, 0.96), Tokens.R_PILL)
	top.add_theme_stylebox_override("panel", sb)
	top.set_anchors_preset(PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 16
	top.offset_bottom = 64
	var row := HBoxContainer.new()
	row.add_child(FlowIslands.circle_btn("‹", func(): FlowRouter.edit_3d(self), 36, Color(0.22, 0.22, 0.24), Color.WHITE))
	var title := Studio.label("Elevation Index", Tokens.FONT_SECTION, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(title)
	row.add_child(Studio.label("All", Tokens.FONT_CAPTION, Color(0.85, 0.85, 0.88)))
	top.add_child(row)
	add_child(top)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	grid.offset_left = 20
	grid.offset_right = -20
	grid.offset_top = 88
	grid.offset_bottom = -88
	add_child(grid)
	for i in 4:
		var card := PanelContainer.new()
		var cs := FlowIslands.frost(Color(0.14, 0.14, 0.16, 1), 16)
		cs.shadow_size = 8
		card.add_theme_stylebox_override("panel", cs)
		card.custom_minimum_size = Vector2(0, 160)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lab := Studio.label("立面 %d" % (i + 1), Tokens.FONT_CAPTION, Color(0.82, 0.82, 0.86))
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(lab)
		grid.add_child(card)

	var dock := PanelContainer.new()
	dock.add_theme_stylebox_override("panel", FlowIslands.frost(Color(0.16, 0.16, 0.18, 0.96)))
	dock.set_anchors_preset(PRESET_BOTTOM_WIDE)
	dock.offset_left = 40
	dock.offset_right = -40
	dock.offset_top = -72
	dock.offset_bottom = -18
	var drow := HBoxContainer.new()
	drow.alignment = BoxContainer.ALIGNMENT_CENTER
	drow.add_child(Studio.label("Annotation", Tokens.FONT_CAPTION, Color.WHITE))
	drow.add_child(Studio.label("  ·  Draw", Tokens.FONT_CAPTION, Color(0.75, 0.75, 0.78)))
	dock.add_child(drow)
	add_child(dock)
