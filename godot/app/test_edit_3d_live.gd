extends Node
## Headless check: live wall-end drag mutates a local SceneIR copy and rebuilds
## BoxMesh solids without writing C API millimetres until commit.

func _ready() -> void:
	if Session == null or not Session.has_core():
		printerr("FAIL: no TopoRoomHost")
		get_tree().quit(1)
		return
	var err := Session.load_fixture_json("res://fixtures/rect-room-v02-archway-clearheight.sceneir.json")
	if not str(err).is_empty():
		printerr("FAIL: load fixture %s" % err)
		get_tree().quit(1)
		return
	var edit: Node3D = preload("res://app/edit_3d.tscn").instantiate()
	add_child(edit)
	await get_tree().process_frame
	await get_tree().process_frame
	if not edit.has_method("_apply_live_preview"):
		printerr("FAIL: missing _apply_live_preview")
		get_tree().quit(1)
		return
	var walls: Array = edit._walls()
	if walls.is_empty() or typeof(walls[0]) != TYPE_DICTIONARY:
		printerr("FAIL: no walls")
		get_tree().quit(1)
		return
	var w: Dictionary = walls[0]
	var a: Dictionary = w.get("start", {})
	var old_x := float(a.get("x", 0))
	var old_y := float(a.get("y", 0))
	var new_x := old_x + 400.0
	var new_y := old_y + 200.0
	var truth_before := Session.sceneir_json()
	edit._drag = {
		"pick": "wall_end",
		"wall_id": str(w.get("id", "")),
		"end": "start",
		"orig_x_mm": old_x,
		"orig_y_mm": old_y,
		"x_mm": new_x,
		"y_mm": new_y,
	}
	edit._drag_base = edit._snapshot.duplicate(true)
	edit._live_preview = true
	var solids_before: int = edit._solids.get_child_count()
	edit._apply_live_preview()
	var walls2: Array = edit._walls()
	var a2: Dictionary = walls2[0].get("start", {})
	if abs(float(a2.get("x", 0)) - new_x) > 0.51 or abs(float(a2.get("y", 0)) - new_y) > 0.51:
		printerr("FAIL: preview snapshot not mutated (got %s,%s want %s,%s)" % [a2.get("x"), a2.get("y"), new_x, new_y])
		get_tree().quit(1)
		return
	if edit._solids.get_child_count() < 2 or edit._solids.get_child_count() == 0:
		printerr("FAIL: solids not rebuilt during live preview")
		get_tree().quit(1)
		return
	if Session.sceneir_json() != truth_before:
		printerr("FAIL: Session SceneIR changed during live preview (must wait for pointer-up)")
		get_tree().quit(1)
		return
	if solids_before < 1:
		printerr("FAIL: no solids before preview")
		get_tree().quit(1)
		return
	var tip: String = edit._handle_tip("wall_end", "")
	if tip != "墙端点：拖动改墙线":
		printerr("FAIL: wall-end tip %s" % tip)
		get_tree().quit(1)
		return
	var width_tip: String = edit._handle_tip("opening_width", "door")
	if not width_tip.contains("拖动改净宽"):
		printerr("FAIL: opening-width tip %s" % width_tip)
		get_tree().quit(1)
		return
	var storey_tip: String = edit._handle_tip("storey_height", "")
	if storey_tip != "层高角点：拖动改层高":
		printerr("FAIL: storey tip %s" % storey_tip)
		get_tree().quit(1)
		return
	print("OK: live wall preview mutates local SceneIR + BoxMesh; C API unchanged; tips present")
	print("solids_before=%d solids_after=%d" % [solids_before, edit._solids.get_child_count()])
	get_tree().quit(0)
