extends Control
## Headless screenshot helper. Not the product main scene.


func _ready() -> void:
	var out_dir := "/opt/cursor/artifacts"
	DirAccess.make_dir_recursive_absolute(out_dir)
	for step in ["calibrate", "review_walls", "library", "lwh", "fab", "place_3d"]:
		Session.mark_coach(step)
	var fixture := FileAccess.get_file_as_string("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json")
	var main: Control = preload("res://app/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	if main.has_method("apply_preview_json"):
		main.apply_preview_json(fixture)
	await get_tree().create_timer(0.35).timeout
	await _shot(out_dir.path_join("toporoom-ui-home.png"))
	if main.has_method("_show_guide"):
		main._show_guide()
	if main.has_method("apply_preview_json"):
		main.apply_preview_json(fixture)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	await _shot(out_dir.path_join("toporoom-ui-guide.png"))
	main.visible = false
	var photo: Control = preload("res://app/photo_stub.tscn").instantiate()
	add_child(photo)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await _shot(out_dir.path_join("toporoom-ui-photo.png"))
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir().path_join("imports"))
	var demo := Image.create(720, 420, false, Image.FORMAT_RGB8)
	demo.fill(Color("E8F0FE"))
	for y in range(40, 380, 2):
		demo.set_pixel(80, y, Color("3D4248"))
		demo.set_pixel(640, y, Color("3D4248"))
	for x in range(80, 640, 2):
		demo.set_pixel(x, 40, Color("E07050"))
		demo.set_pixel(x, 380, Color("E07050"))
	var demo_path := OS.get_user_data_dir().path_join("imports/preview_demo.png")
	demo.save_png(demo_path)
	if photo.has_method("_show_preview"):
		photo._show_preview(demo_path)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
		await _shot(out_dir.path_join("toporoom-ui-photo-preview.png"))
	if photo.has_method("_show_calibrate"):
		photo._show_calibrate(demo_path)
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		await _shot(out_dir.path_join("toporoom-ui-calibrate.png"))
	if Session.has_core():
		Session.import_photo_fake("fixture:photo")
		if photo.has_method("_show_review"):
			photo._show_review()
		await get_tree().process_frame
		await get_tree().create_timer(0.35).timeout
		if photo._snack:
			photo._snack.visible = false
		if photo._coach:
			photo._coach.visible = false
		photo._canvas.selected_id = "wall_s"
		photo._canvas.queue_redraw()
		photo._refresh_selection()
		await get_tree().process_frame
		await get_tree().create_timer(0.25).timeout
		await _shot(out_dir.path_join("toporoom-ui-photo-review.png"))
		if photo.has_method("_show_demolish"):
			photo._show_demolish()
		photo._canvas.selected_id = "wall_p"
		photo._canvas.queue_redraw()
		await get_tree().process_frame
		await get_tree().create_timer(0.35).timeout
		if photo._snack:
			photo._snack.visible = false
		await _shot(out_dir.path_join("toporoom-ui-photo-demolish.png"))
		if photo.has_method("_with_force"):
			photo._canvas.selected_id = "wall_n"
			photo._confirm_label.text = "这面墙标成了承重墙。拆除会改写方案，需要你再点一次确认。"
			photo._confirm.visible = true
			await get_tree().process_frame
			await get_tree().create_timer(0.25).timeout
			await _shot(out_dir.path_join("toporoom-ui-photo-confirm.png"))
	if is_instance_valid(photo):
		photo.visible = false
	if is_instance_valid(main):
		main.visible = false
	var edit: Node3D = null
	if Session.has_core():
		Session.load_fixture_json("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json")
		edit = preload("res://app/edit_3d.tscn").instantiate()
		add_child(edit)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(0.8).timeout
		await _shot(out_dir.path_join("toporoom-ui-edit-3d.png"))
		if edit.has_method("_open_ruler"):
			edit._open_ruler()
			await get_tree().process_frame
			await get_tree().create_timer(0.25).timeout
			await _shot(out_dir.path_join("toporoom-ui-ruler.png"))
			if edit._ruler:
				edit._ruler.visible = false
		Session.set_ruler("dims_3d", true)
		if edit.has_method("_sync_dims_from_prefs"):
			edit._sync_dims_from_prefs()
		await get_tree().process_frame
		await get_tree().create_timer(0.25).timeout
		await _shot(out_dir.path_join("toporoom-ui-dims.png"))
		if edit.has_node("Lighting") and edit.get_node("Lighting").has_method("apply_preset"):
			edit.get_node("Lighting").apply_preset("warm")
			await get_tree().create_timer(0.35).timeout
			await _shot(out_dir.path_join("toporoom-ui-edit-3d-warm.png"))
	if is_instance_valid(edit):
		edit.visible = false
	var elev: Control = preload("res://app/elevation_index.tscn").instantiate()
	add_child(elev)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await _shot(out_dir.path_join("toporoom-ui-elevation.png"))
	print("UI screenshots written to ", out_dir)
	get_tree().quit()


func _shot(path: String) -> void:
	RenderingServer.force_draw()
	await get_tree().process_frame
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("no viewport texture")
		return
	var img := tex.get_image()
	img.save_png(path)
	print("wrote ", path, " ", img.get_width(), "x", img.get_height())
