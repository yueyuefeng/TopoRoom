extends Control
## Capture 自由绘制: new plan → blank canvas → rectangle → 2D → 3D.


func _ready() -> void:
	var out_dir := "/opt/cursor/artifacts"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var docs := ProjectSettings.globalize_path("res://").path_join("../docs/screenshots/free_draw")
	DirAccess.make_dir_recursive_absolute(docs)

	var neu: Control = preload("res://app/joyplan_flow/new_plan.tscn").instantiate()
	add_child(neu)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	await _shot(docs, out_dir, "01_new_plan.png")
	neu.queue_free()

	Session.start_free_draw(true)
	var draw: Control = preload("res://app/joyplan_flow/free_draw.tscn").instantiate()
	add_child(draw)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	if Session.drawn_wall_count() != 0:
		push_error("free-draw started with walls")
	await _shot(docs, out_dir, "02_blank_canvas.png")

	var err := ""
	if draw.has_method("draw_rectangle_mm"):
		err = draw.draw_rectangle_mm(4000.0, 3000.0)
	else:
		err = Session.add_drawn_wall(0, 0, 4000, 0)
	if err != "":
		push_error("draw rectangle failed: %s" % err)
	if Session.drawn_wall_count() < 4:
		push_error("expected 4 walls, got %d" % Session.drawn_wall_count())
	else:
		print("OK free-draw rectangle walls=%d" % Session.drawn_wall_count())
	if draw.has_method("_queue_draw"):
		draw._queue_draw()
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	await _shot(docs, out_dir, "03_rectangle.png")

	if draw.has_method("_finish"):
		# Don't change scene in capture — screenshot 2D separately.
		pass
	draw.queue_free()

	Session.from_free_draw = true
	var edit2: Control = preload("res://app/joyplan_flow/edit_2d.tscn").instantiate()
	add_child(edit2)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	if edit2._canvas:
		edit2._canvas.set_sceneir_json(Session.sceneir_json())
		if Session.sceneir_json().find("wall_d") < 0:
			push_error("2D missing drawn walls")
		else:
			print("OK 2D sees free-draw walls")
	await _shot(docs, out_dir, "04_edit_2d.png")
	edit2.queue_free()

	var edit3: Control = preload("res://app/joyplan_flow/edit_3d.tscn").instantiate()
	add_child(edit3)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await _shot(docs, out_dir, "05_edit_3d.png")
	edit3.queue_free()
	print("OK free-draw capture done")
	get_tree().quit()


func _shot(docs: String, out_dir: String, file: String) -> void:
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	var abs_path := out_dir.path_join("free_draw_" + file)
	img.save_png(abs_path)
	DirAccess.copy_absolute(abs_path, docs.path_join(file))
	DirAccess.copy_absolute(abs_path, out_dir.path_join("joyplan_free_draw_" + file))
