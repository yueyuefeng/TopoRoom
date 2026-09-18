extends Control
## Capture JoyPlan click-path frames (home → projects → new plan → pick → 1/2 → 2/2 → 2D).


func _ready() -> void:
	var out_dir := "/opt/cursor/artifacts"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var docs := ProjectSettings.globalize_path("res://").path_join("../docs/screenshots/joyplan_click_path")
	DirAccess.make_dir_recursive_absolute(docs)

	var home: Control = preload("res://app/joyplan_flow/home.tscn").instantiate()
	add_child(home)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	await _shot(docs, out_dir, "01_home.png")
	home.queue_free()

	var projects: Control = preload("res://app/joyplan_flow/projects.tscn").instantiate()
	add_child(projects)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	await _shot(docs, out_dir, "02_projects.png")
	projects.queue_free()

	var neu: Control = preload("res://app/joyplan_flow/new_plan.tscn").instantiate()
	add_child(neu)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	await _shot(docs, out_dir, "03_new_plan.png")
	if neu.has_method("_open_pick"):
		neu._open_pick()
		await get_tree().process_frame
		await get_tree().create_timer(0.2).timeout
		await _shot(docs, out_dir, "04_pick_source.png")
	neu.queue_free()

	var gold := Session.load_gold_sample()
	if gold.is_empty():
		gold = ProjectSettings.globalize_path("res://fixtures/apt-plan-user-01.png")
		Session.last_import_path = gold
		Session.last_import_uri = gold
	var scale: Control = preload("res://app/joyplan_flow/scale_calibrate.tscn").instantiate()
	add_child(scale)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await _shot(docs, out_dir, "05_scale_1of2.png")
	if not ("_img" in scale) or scale._img == null:
		push_error("示例户型 did not load into 1/2 临摹图比例")
	else:
		print("OK sample→1/2 scale image %dx%d" % [scale._img.get_width(), scale._img.get_height()])
		var px: float = scale._a.distance_to(scale._b)
		var mm: float = scale._mm.text.strip_edges().to_float()
		if mm < 10.0:
			mm = 900.0
		Session.last_scale_mm = mm
		Session.last_scale_mm_per_px = (mm / px) if px >= 4.0 else 0.0
	scale.queue_free()

	if Session.sceneir_json().find("wall_") < 0:
		if Session.has_core():
			Session.import_photo_fake("fixture:photo")
		else:
			Session.load_fixture_json("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json")
	print("OK sample→vision walls=%s" % Session.sceneir_json().find("\"walls\""))

	var gen: Control = preload("res://app/joyplan_flow/generate_space.tscn").instantiate()
	add_child(gen)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await _shot(docs, out_dir, "06_generate_2of2.png")
	gen.queue_free()

	Session.coach_seen.erase("library")
	var edit2: Control = preload("res://app/joyplan_flow/edit_2d.tscn").instantiate()
	add_child(edit2)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	if edit2._canvas:
		edit2._canvas.load_photo(gold)
		edit2._canvas.selected_id = "wall_s"
		edit2._canvas.queue_redraw()
		edit2._refresh_readout()
		edit2._place_ctx()
	await _shot(docs, out_dir, "07_edit_2d.png")
	if edit2.has_method("_show_add_menu"):
		edit2._show_add_menu()
		await get_tree().process_frame
		await get_tree().create_timer(0.15).timeout
		await _shot(docs, out_dir, "08_edit_2d_plus_menu.png")
	edit2.queue_free()
	print("OK click-path capture done")
	get_tree().quit()


func _shot(docs: String, out_dir: String, file: String) -> void:
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	var abs_path := out_dir.path_join("click_" + file)
	img.save_png(abs_path)
	DirAccess.copy_absolute(abs_path, docs.path_join(file))
	DirAccess.copy_absolute(abs_path, out_dir.path_join("joyplan_click_" + file))
