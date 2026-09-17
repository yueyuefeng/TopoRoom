extends Control
## 拍户型图占位：方向可见，识别流程尚未接入。


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	var bg := ColorRect.new()
	bg.color = Tokens.BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", Tokens.S3)
	margin.add_theme_constant_override("margin_right", Tokens.S3)
	margin.add_theme_constant_override("margin_top", Tokens.S3)
	margin.add_theme_constant_override("margin_bottom", Tokens.S3)
	add_child(margin)

	var col := Studio.vbox(Tokens.S2)
	margin.add_child(col)

	var top := Studio.hbox(Tokens.S2)
	top.add_child(Studio.ghost("返回", func(): get_tree().change_scene_to_file("res://app/main.tscn")))
	var title := Studio.section("拍户型图")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(88, 0)
	top.add_child(spacer)
	col.add_child(top)
	col.add_child(Studio.spacer(Tokens.S3))

	var hero := Studio.card("HeroCard")
	var inner := Studio.vbox(Tokens.S2)
	hero.add_child(inner)
	inner.add_child(_camera_mark())
	var h := Studio.display("即将支持")
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(h)
	var body := Studio.caption("拍摄现场墙面后识别墙段，结果仍写入 SceneIR，不会把照片网格当成尺寸真相。当前请用「新建方案」或「引导量房」。")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(body)
	col.add_child(hero)

	var cta := Studio.primary("回到工作台", func(): get_tree().change_scene_to_file("res://app/main.tscn"))
	cta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(cta)
	var guide := Studio.ghost("改为引导量房", func():
		Session.screen = "guide"
		get_tree().change_scene_to_file("res://app/main.tscn")
	)
	guide.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(guide)


func _camera_mark() -> Control:
	var wrap := CenterContainer.new()
	wrap.custom_minimum_size = Vector2(0, 168)
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Tokens.SURFACE_MUTED
	sb.corner_radius_top_left = Tokens.R_LG
	sb.corner_radius_top_right = Tokens.R_LG
	sb.corner_radius_bottom_left = Tokens.R_LG
	sb.corner_radius_bottom_right = Tokens.R_LG
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	frame.custom_minimum_size = Vector2(220, 0)
	frame.add_theme_stylebox_override("panel", sb)
	var inner := Studio.vbox(6)
	var lens := PanelContainer.new()
	var ring := StyleBoxFlat.new()
	ring.bg_color = Tokens.SURFACE
	ring.border_color = Tokens.PRIMARY
	ring.set_border_width_all(3)
	ring.corner_radius_top_left = 40
	ring.corner_radius_top_right = 40
	ring.corner_radius_bottom_left = 40
	ring.corner_radius_bottom_right = 40
	ring.content_margin_left = 18
	ring.content_margin_right = 18
	ring.content_margin_top = 18
	ring.content_margin_bottom = 18
	lens.add_theme_stylebox_override("panel", ring)
	var dot := ColorRect.new()
	dot.color = Tokens.PRIMARY
	dot.custom_minimum_size = Vector2(12, 12)
	lens.add_child(dot)
	var cap := CenterContainer.new()
	cap.add_child(lens)
	inner.add_child(cap)
	var hint := Studio.caption("现场拍照识别墙段")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(hint)
	frame.add_child(inner)
	wrap.add_child(frame)
	return wrap
