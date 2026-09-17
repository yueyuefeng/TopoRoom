extends Control
## Headless screenshot helper. Not the product main scene.


func _ready() -> void:
	var out_dir := "/opt/cursor/artifacts"
	DirAccess.make_dir_recursive_absolute(out_dir)
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
	if Session.has_core():
		Session.import_photo_fake("fixture:photo")
		if photo.has_method("_show_review"):
			photo._show_review()
		await get_tree().process_frame
		await get_tree().create_timer(0.35).timeout
		await _shot(out_dir.path_join("toporoom-ui-photo-review.png"))
		if photo.has_method("_show_demolish"):
			photo._show_demolish()
		photo._canvas.selected_id = "wall_p"
		photo._canvas.queue_redraw()
		await get_tree().process_frame
		await get_tree().create_timer(0.35).timeout
		await _shot(out_dir.path_join("toporoom-ui-photo-demolish.png"))
		if photo.has_method("_with_force"):
			photo._canvas.selected_id = "wall_n"
			photo._confirm_label.text = "「wall_n」是承重/剪力墙。拆除或打断将改写 SceneIR，需确认。"
			photo._confirm.visible = true
			await get_tree().process_frame
			await get_tree().create_timer(0.25).timeout
			await _shot(out_dir.path_join("toporoom-ui-photo-confirm.png"))
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
