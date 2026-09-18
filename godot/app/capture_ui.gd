extends Control
## Headless screenshot helper for JoyPlan flow S1–S8. Not the product main scene.


func _ready() -> void:
	var out_dir := "/opt/cursor/artifacts"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var docs := ProjectSettings.globalize_path("res://").path_join("../docs/screenshots/joyplan_flow")
	DirAccess.make_dir_recursive_absolute(docs)
	for step in ["library", "review_walls", "place_3d"]:
		Session.mark_coach(step)

	var home: Control = preload("res://app/joyplan_flow/home.tscn").instantiate()
	add_child(home)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	await _shot(out_dir.path_join("s1_home.png"))
	home.queue_free()

	var scale: Control = preload("res://app/joyplan_flow/scale_calibrate.tscn").instantiate()
	add_child(scale)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	await _shot(out_dir.path_join("s2_scale_calibration.png"))
	if scale.has_method("_show_loupe") and scale._img:
		scale._drag = 1
		scale._show_loupe(scale._a)
		await get_tree().process_frame
		await _shot(out_dir.path_join("s2_scale_loupe.png"))
		scale._loupe.visible = false
	scale.queue_free()

	if Session.has_core():
		Session.import_photo_fake("fixture:photo")
	else:
		Session.load_fixture_json("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json")

	var edit2: Control = preload("res://app/joyplan_flow/edit_2d.tscn").instantiate()
	add_child(edit2)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	if edit2._canvas:
		edit2._canvas.selected_id = "wall_s"
		edit2._canvas.queue_redraw()
		edit2._refresh_readout()
		edit2._place_ctx()
	await get_tree().process_frame
	await _shot(out_dir.path_join("s3_2d_base_edit.png"))
	if edit2.has_method("show_library"):
		edit2.show_library(true)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	await _shot(out_dir.path_join("s4_library_sheet.png"))
	edit2.queue_free()

	var edit3: Node3D = preload("res://app/joyplan_flow/edit_3d.tscn").instantiate()
	add_child(edit3)
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	await _shot(out_dir.path_join("s5_3d_walkthrough.png"))
	if edit3._ruler and edit3._ruler.has_method("present"):
		edit3._ruler.present()
	await get_tree().process_frame
	await _shot(out_dir.path_join("s6_ruler_sheet.png"))
	if edit3._ruler:
		edit3._ruler.visible = false
	edit3._show_dims = true
	if edit3._dim_overlay:
		edit3._dim_overlay.visible = true
		edit3._dim_overlay.queue_redraw()
	await get_tree().process_frame
	await _shot(out_dir.path_join("s7_dimension_hud.png"))
	edit3.queue_free()

	var elev: Control = preload("res://app/joyplan_flow/elevation_index.tscn").instantiate()
	add_child(elev)
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	await _shot(out_dir.path_join("s8_elevation_index.png"))
	get_tree().quit()


func _shot(path: String) -> void:
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(path)
	var docs := ProjectSettings.globalize_path("res://").path_join("../docs/screenshots/joyplan_flow")
	DirAccess.copy_absolute(path, docs.path_join(path.get_file()))
