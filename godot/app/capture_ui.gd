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
