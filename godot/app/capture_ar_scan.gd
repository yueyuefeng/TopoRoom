extends Control
## Capture AR扫描: new plan → scan UI → demo room → 2D → 3D.


func _ready() -> void:
	var out_dir := "/opt/cursor/artifacts"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var docs := ProjectSettings.globalize_path("res://").path_join("../docs/screenshots/ar_scan")
	DirAccess.make_dir_recursive_absolute(docs)

	var neu: Control = preload("res://app/joyplan_flow/new_plan.tscn").instantiate()
	add_child(neu)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	await _shot(docs, out_dir, "01_new_plan.png")
	neu.queue_free()

	Session.start_ar_scan(true)
	var scan: Control = preload("res://app/joyplan_flow/ar_scan.tscn").instantiate()
	add_child(scan)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	if Session.drawn_wall_count() != 0:
		push_error("ar-scan started with walls")
	await _shot(docs, out_dir, "02_scan_ui.png")

	var err := ""
	if scan.has_method("load_demo_room"):
		err = scan.load_demo_room(4000.0, 3000.0)
	else:
		err = Session.ar_demo_rectangle(4000.0, 3000.0)
	if err != "":
		push_error("demo room failed: %s" % err)
	if Session.drawn_wall_count() < 4:
		push_error("expected 4 AR walls, got %d" % Session.drawn_wall_count())
	else:
		print("OK ar-scan demo walls=%d" % Session.drawn_wall_count())
	if scan.has_method("_refresh_chrome"):
		scan._refresh_chrome()
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	await _shot(docs, out_dir, "03_demo_room.png")
	scan.queue_free()

	Session.from_ar_scan = true
	var edit2: Control = preload("res://app/joyplan_flow/edit_2d.tscn").instantiate()
	add_child(edit2)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	if edit2._canvas:
		edit2._canvas.set_sceneir_json(Session.sceneir_json())
		if Session.sceneir_json().find("wall_a") < 0:
			push_error("2D missing AR walls")
		else:
			print("OK 2D sees AR walls")
	await _shot(docs, out_dir, "04_edit_2d.png")
	edit2.queue_free()

	var edit3: Node3D = preload("res://app/joyplan_flow/edit_3d.tscn").instantiate()
	add_child(edit3)
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout
	if edit3.has_method("_orbit"):
		edit3._pitch = -0.82
		edit3._distance = 13.5
		edit3._orbit()
	await get_tree().process_frame
	await _shot(docs, out_dir, "05_edit_3d.png")
	edit3.queue_free()
	print("OK ar-scan capture done")
	get_tree().quit()


func _shot(docs: String, out_dir: String, file: String) -> void:
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	var abs_path := out_dir.path_join("ar_scan_" + file)
	img.save_png(abs_path)
	DirAccess.copy_absolute(abs_path, docs.path_join(file))
	DirAccess.copy_absolute(abs_path, out_dir.path_join("joyplan_ar_scan_" + file))
