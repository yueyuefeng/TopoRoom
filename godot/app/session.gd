extends Node
## Autoload InteractionShell. Commands go to TopoRoomHost (GDExtension → C API).
## Never treat Godot nodes or .glb meshes as editable truth.

signal document_changed
signal log_line(text: String)

var host: RefCounted
var last_error: String = ""
var last_export_dir: String = ""
var last_glb_path: String = ""
var glb_ok: bool = false
var fake_laser_queue: Array[float] = [4000.0, 3000.0]
var opening_serial: int = 0
var key_serial: int = 0
var screen: String = "home"  # home | guide | photo
var last_rebuild: Dictionary = {}
var keep_preview: bool = false
var preview_sceneir_json: String = ""
var photo_intent: String = ""  # camera | gallery | pick
var last_import_path: String = ""
var last_import_uri: String = ""
var last_vision: Dictionary = {}

func _ready() -> void:
	if ClassDB.class_exists("TopoRoomHost"):
		host = ClassDB.instantiate("TopoRoomHost")
		host.create_document("doc_godot")
		opening_serial = 0
		key_serial = 0
		guide_mark_host_ok(true)
		auto_save()
		keep_preview = false
		preview_sceneir_json = sceneir_json()
		screen = "home"
		_log("Godot 宿主已连接 C API %s" % host.version())
	else:
		_log("未加载 GDExtension。请先编译 godot/bin/libtoporoom.*.so")


func has_core() -> bool:
	return host != null


func _log(text: String) -> void:
	emit_signal("log_line", text)


func _fail(err: String) -> String:
	last_error = err
	_log("错误: %s" % err)
	emit_signal("document_changed")
	return err


func _ok(msg: String) -> String:
	last_error = ""
	if not keep_preview:
		preview_sceneir_json = sceneir_json()
	_log(msg)
	emit_signal("document_changed")
	return ""


func _after_structural_edit(ok_msg: String) -> String:
	# Gizmo/command commit: auto_save SceneIR, probe StatusGate.
	# Fault keeps the previous solid preview; SceneIR remains Domain truth.
	var probe: Dictionary = rebuild_probe()
	last_rebuild = probe
	if not bool(probe.get("ok", false)):
		keep_preview = true
		last_error = str(probe.get("error", "rebuild fault"))
		auto_save()
		_log("StatusGate Fault: %s — 预览保持上一版实体，未把拖动手柄当作尺寸真相" % last_error)
		emit_signal("document_changed")
		return last_error
	keep_preview = false
	auto_save()
	return _ok(ok_msg)


func _result(d: Dictionary, ok_msg: String) -> String:
	if d.get("ok", false):
		return _ok(ok_msg)
	return _fail(str(d.get("error", "error")))


func schemes_dir() -> String:
	return OS.get_user_data_dir().path_join("schemes")


func export_dir() -> String:
	return OS.get_user_data_dir().path_join("export")


func scheme_path(id: String = "") -> String:
	var doc_id := id
	if doc_id.is_empty() and host:
		doc_id = host.document_id()
	if doc_id.is_empty():
		doc_id = "doc"
	return schemes_dir().path_join("%s.sceneir.json" % doc_id)


func auto_save() -> void:
	if host == null or not host.has_document():
		return
	DirAccess.make_dir_recursive_absolute(schemes_dir())
	host.save_file(scheme_path())


func new_scheme(id: String = "doc_godot") -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.create_document(id)
	opening_serial = 0
	key_serial = 0
	fake_laser_queue = [4000.0, 3000.0]
	glb_ok = false
	last_glb_path = ""
	guide_mark_host_ok(true)
	keep_preview = false
	auto_save()
	preview_sceneir_json = sceneir_json()
	screen = "guide"
	return _result(d, "新建方案 %s" % id)


func load_scheme(path: String) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.load_file(path)
	if d.get("ok", false):
		host.guide_mark_host_ok(true)
		host.guide_sync_from_document(false)
		opening_serial = 0
		key_serial = 0
		keep_preview = false
		preview_sceneir_json = sceneir_json()
	return _result(d, "加载方案 %s" % path.get_file())


func load_fixture_json(res_path: String) -> String:
	if host == null:
		return _fail("no core")
	if not FileAccess.file_exists(res_path):
		return _fail("missing fixture %s" % res_path)
	var f := FileAccess.open(res_path, FileAccess.READ)
	var text := f.get_as_text()
	var d: Dictionary = host.load_json(text)
	if d.get("ok", false):
		host.guide_mark_host_ok(true)
		host.guide_sync_from_document(false)
		keep_preview = false
		preview_sceneir_json = sceneir_json()
	return _result(d, "加载夹具 %s" % res_path.get_file())


func add_rectangle_walls() -> String:
	if host == null:
		return _fail("no core")
	var storey: String = host.first_storey_id()
	var rect := [
		["wall_n", 0.0, 3000.0, 4000.0, 3000.0],
		["wall_e", 4000.0, 3000.0, 4000.0, 0.0],
		["wall_s", 4000.0, 0.0, 0.0, 0.0],
		["wall_w", 0.0, 0.0, 0.0, 3000.0],
	]
	for item in rect:
		var d: Dictionary = host.add_wall(storey, item[0], item[1], item[2], item[3], item[4], 200.0, 2800.0)
		if not d.get("ok", false):
			return _fail(str(d.get("error", "add_wall")))
		host.guide_note_wall()
	host.guide_sync_from_document(false)
	auto_save()
	return _ok("画墙：矩形一室 4000×3000")


func measure_laser_fake() -> String:
	if host == null:
		return _fail("no core")
	var mm: float = 4000.0
	if not fake_laser_queue.is_empty():
		mm = fake_laser_queue.pop_front()
	key_serial += 1
	var d: Dictionary = host.set_measurement(
		"m_key_%d" % key_serial, mm, "laser", "fake_laser", "wall_s", "", "", ""
	)
	if not d.get("ok", false):
		key_serial -= 1
		return _fail(str(d.get("error", "measurement")))
	host.guide_note_key("laser", false)
	host.guide_sync_from_document(false)
	auto_save()
	return _ok("关键尺寸 Fake激光 %smm" % str(mm))


func measure_typed(value_mm: float, explicit: bool) -> String:
	if host == null:
		return _fail("no core")
	key_serial += 1
	var d: Dictionary = host.set_measurement(
		"m_key_%d" % key_serial, value_mm, "typed", "", "wall_s", "", "", ""
	)
	if not d.get("ok", false):
		key_serial -= 1
		return _fail(str(d.get("error", "measurement")))
	host.guide_note_key("typed", explicit)
	host.guide_sync_from_document(false)
	auto_save()
	return _ok("关键尺寸 手输 %smm 确认=%s" % [str(value_mm), str(explicit)])


func add_opening(kind: String) -> String:
	if host == null:
		return _fail("no core")
	opening_serial += 1
	var width := 900.0
	var height := 2100.0
	var sill := 0.0
	if kind == "window":
		width = 1200.0
		height = 1400.0
		sill = 900.0
	elif kind == "archway":
		width = 1200.0
	var d: Dictionary = host.add_opening(
		host.first_storey_id(), "wall_s", "op_%s_%d" % [kind, opening_serial], kind,
		width, height, 800.0, sill
	)
	if not d.get("ok", false):
		opening_serial -= 1
		return _fail(str(d.get("error", "opening")))
	host.guide_note_opening()
	host.guide_sync_from_document(false)
	auto_save()
	var label: String = Tokens.opening_label(kind)
	return _ok("放置%s" % label)


func place_hosted_beam() -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.place_hosted(
		host.first_storey_id(), "beam_1", "beam", 2400.0, 300.0, "wall_n"
	)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "hosted")))
	auto_save()
	return _ok("放置梁 beam_1（宿主墙 wall_n）")


func close_and_set_room() -> String:
	if host == null:
		return _fail("no core")
	var storey: String = host.first_storey_id()
	var d: Dictionary = host.close_room(storey, "room_1", "wall_n,wall_e,wall_s,wall_w")
	if not d.get("ok", false):
		return _fail(str(d.get("error", "close_room")))
	host.set_room_attributes(storey, "room_1", "客厅", "interior", true, 2650.0)
	host.guide_sync_from_document(false)
	auto_save()
	return _ok("闭合房间 客厅 · 净高 2650mm")


func set_storey_height(height_mm: float) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.set_storey_height(host.first_storey_id(), height_mm, true)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "storey_height")))
	return _after_structural_edit("层高 %smm" % str(height_mm))


func set_wall_height_mm(wall_id: String, height_mm: float) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.set_wall_height(host.first_storey_id(), wall_id, height_mm)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "set_wall_height")))
	return _after_structural_edit("墙高 %s %smm" % [wall_id, str(height_mm)])


func set_wall_kind(wall_id: String, kind: String) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.set_wall_kind(host.first_storey_id(), wall_id, kind)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "set_wall_kind")))
	var label: String = "承重/剪力墙" if kind == "shearWall" else "非承重/砌体"
	return _after_structural_edit("墙 %s → %s" % [wall_id, label])


func demolish_wall(wall_id: String, force: bool = false) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.demolish_wall(host.first_storey_id(), wall_id, force)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "demolish_wall")))
	return _after_structural_edit("拆除墙 %s" % wall_id)


func split_wall(wall_id: String, offset_mm: float) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.split_wall(host.first_storey_id(), wall_id, offset_mm)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "split_wall")))
	return _after_structural_edit("打断墙 %s" % wall_id)


func partial_demolish(wall_id: String, offset_mm: float, length_mm: float, force: bool = false) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.partial_demolish(host.first_storey_id(), wall_id, offset_mm, length_mm, force)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "partial_demolish")))
	return _after_structural_edit("局部拆除 %s" % wall_id)


func punch_opening(wall_id: String, kind: String, force: bool = false) -> String:
	if host == null:
		return _fail("no core")
	opening_serial += 1
	var oid: String = "op_punch_%d" % opening_serial
	var d: Dictionary = host.punch_opening(
		host.first_storey_id(), wall_id, oid, kind, 900.0, 2100.0, 200.0, 0.0, force
	)
	if not d.get("ok", false):
		opening_serial -= 1
		return _fail(str(d.get("error", "punch_opening")))
	var label: String = Tokens.opening_label(kind)
	return _after_structural_edit("打洞 %s @ %s" % [label, wall_id])


func imports_dir() -> String:
	return OS.get_user_data_dir().path_join("imports")


func store_imported_image(src: String) -> String:
	if src.is_empty() or src.begins_with("fixture:"):
		last_import_path = ""
		last_import_uri = src
		return src
	var abs_src := src
	if src.begins_with("user://") or src.begins_with("res://"):
		abs_src = ProjectSettings.globalize_path(src)
	DirAccess.make_dir_recursive_absolute(imports_dir())
	var ext := src.get_extension().to_lower()
	if ext.is_empty():
		ext = "jpg"
	var dest := imports_dir().path_join("import_%d.%s" % [Time.get_ticks_msec(), ext])
	if abs_src == dest:
		last_import_path = dest
		last_import_uri = dest
		return dest
	var copied := DirAccess.copy_absolute(abs_src, dest)
	if copied != OK:
		var inf := FileAccess.open(abs_src, FileAccess.READ)
		if inf == null:
			return ""
		var outf := FileAccess.open(dest, FileAccess.WRITE)
		if outf == null:
			return ""
		outf.store_buffer(inf.get_buffer(inf.get_length()))
	last_import_path = dest
	last_import_uri = dest
	return dest


func import_photo_fake(image_uri: String = "fixture:photo") -> String:
	if host == null:
		return _fail("no core")
	var stored: String = store_imported_image(image_uri)
	if stored.is_empty() and not image_uri.begins_with("fixture:"):
		return _fail("无法保存照片")
	var vision_uri: String = stored if not stored.is_empty() else image_uri
	var id: String = "doc_photo_%d" % Time.get_ticks_msec()
	var created: Dictionary = host.create_document(id)
	if not created.get("ok", false):
		return _fail(str(created.get("error", "create")))
	opening_serial = 0
	key_serial = 0
	glb_ok = false
	last_glb_path = ""
	keep_preview = false
	guide_mark_host_ok(true)
	var d: Dictionary = host.import_fake_vision(vision_uri)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "vision")))
	host.guide_note_wall()
	host.guide_sync_from_document(false)
	auto_save()
	preview_sceneir_json = sceneir_json()
	screen = "photo"
	last_vision = {
		"adapter": "fake",
		"wall_count": 5,
		"opening_count": 0,
		"shear_count": 4,
		"masonry_count": 1,
		"door_count": 0,
		"window_count": 0,
	}
	return _ok("已识别墙体：四边承重 + 一道隔墙。尺寸仍以量房命令为准。")


func import_photo_vision(image_uri: String) -> String:
	if host == null:
		return _fail("no core")
	if image_uri.is_empty() or image_uri.begins_with("fixture:"):
		return import_photo_fake(image_uri if not image_uri.is_empty() else "fixture:photo")
	var stored: String = store_imported_image(image_uri)
	if stored.is_empty():
		return _fail("无法保存照片")
	var id: String = "doc_vision_%d" % Time.get_ticks_msec()
	var created: Dictionary = host.create_document(id)
	if not created.get("ok", false):
		return _fail(str(created.get("error", "create")))
	opening_serial = 0
	key_serial = 0
	glb_ok = false
	last_glb_path = ""
	keep_preview = false
	last_vision = {}
	guide_mark_host_ok(true)
	var d: Dictionary = host.import_vision_image(stored)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "vision")))
	last_vision = d
	host.guide_note_wall()
	if int(d.get("opening_count", 0)) > 0:
		host.guide_note_opening()
	host.guide_sync_from_document(false)
	auto_save()
	preview_sceneir_json = sceneir_json()
	screen = "photo"
	var probe: Dictionary = rebuild_probe()
	last_rebuild = probe
	if bool(probe.get("ok", false)):
		keep_preview = false
		var out := export_dir()
		DirAccess.make_dir_recursive_absolute(out)
		var glb_path := out.path_join("room.glb")
		var g: Dictionary = host.export_document("glb", glb_path)
		if bool(g.get("ok", false)):
			glb_ok = true
			last_glb_path = glb_path
			last_export_dir = out
			host.guide_note_rebuild(true)
			host.guide_sync_from_document(true)
	var shear := int(d.get("shear_count", 0))
	var mason := int(d.get("masonry_count", 0))
	var doors := int(d.get("door_count", 0))
	var windows := int(d.get("window_count", 0))
	return _ok("已识别承重 %d、砌体 %d、门 %d、窗 %d。可改类型后进入 3D。" % [shear, mason, doors, windows])


func move_shared_vertex(old_x: float, old_y: float, new_x: float, new_y: float) -> String:
	if host == null:
		return _fail("no core")
	var parsed: Variant = JSON.parse_string(sceneir_json())
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail("no sceneir")
	var storeys: Array = parsed.get("storeys", [])
	if storeys.is_empty() or typeof(storeys[0]) != TYPE_DICTIONARY:
		return _fail("no storey")
	var walls: Array = storeys[0].get("walls", [])
	var storey: String = host.first_storey_id()
	var eps := 0.51
	var any := false
	for w in walls:
		if typeof(w) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = w.get("start", {})
		var b: Dictionary = w.get("end", {})
		var x0 := float(a.get("x", 0))
		var y0 := float(a.get("y", 0))
		var x1 := float(b.get("x", 0))
		var y1 := float(b.get("y", 0))
		var changed := false
		if abs(x0 - old_x) < eps and abs(y0 - old_y) < eps:
			x0 = new_x
			y0 = new_y
			changed = true
		if abs(x1 - old_x) < eps and abs(y1 - old_y) < eps:
			x1 = new_x
			y1 = new_y
			changed = true
		if not changed:
			continue
		var d: Dictionary = host.move_wall(storey, str(w.get("id", "")), x0, y0, x1, y1)
		if not d.get("ok", false):
			return _fail(str(d.get("error", "move_wall")))
		any = true
	if not any:
		return _fail("no shared vertex")
	return _after_structural_edit("移动墙端点")


func update_opening_geom(opening_id: String, kind: String, width_mm: float, height_mm: float, offset_mm: float, sill_mm: float) -> String:
	if host == null:
		return _fail("no core")
	var d: Dictionary = host.update_opening(
		host.first_storey_id(), opening_id, kind, width_mm, height_mm, offset_mm, sill_mm
	)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "update_opening")))
	return _after_structural_edit("更新洞口 %s" % opening_id)


func rebuild_probe() -> Dictionary:
	if host == null:
		return {"ok": false, "status": "", "error": "no core"}
	return host.rebuild_status()


func export_deliverables() -> String:
	if host == null:
		return _fail("no core")
	var out := export_dir()
	DirAccess.make_dir_recursive_absolute(out)
	last_export_dir = out
	var written: Array[String] = []
	glb_ok = false
	last_glb_path = ""
	for fmt in ["dxf", "pdf", "glb"]:
		var path := out.path_join("room.%s" % fmt)
		var d: Dictionary = host.export_document(fmt, path)
		if not d.get("ok", false):
			if fmt == "glb":
				_log("glb 未写出（几何未 OK）: %s" % str(d.get("error", "")))
				continue
			return _fail(str(d.get("error", fmt)))
		written.append(fmt)
		if fmt == "glb":
			glb_ok = true
			last_glb_path = path
	host.guide_note_rebuild(true)
	host.guide_sync_from_document(true)
	auto_save()
	return _ok("导出 %s → %s" % [", ".join(written), out])


func fake_one_room() -> String:
	if host == null:
		return _fail("no core")
	new_scheme("doc_fake")
	var out := export_dir()
	DirAccess.make_dir_recursive_absolute(out)
	var d: Dictionary = host.fake_one_room(out)
	if not d.get("ok", false):
		return _fail(str(d.get("error", "fake")))
	last_export_dir = out
	last_glb_path = out.path_join("room.glb")
	glb_ok = FileAccess.file_exists(last_glb_path)
	auto_save()
	screen = "guide"
	return _ok("Fake 一室回路 → %s" % out)


func run_guided_edit() -> String:
	if host == null:
		return _fail("no core")
	new_scheme("doc_guided")
	var d: Dictionary = host.run_guided_edit()
	if not d.get("ok", false):
		return _fail(str(d.get("error", "guided")))
	auto_save()
	screen = "guide"
	return _ok("引导量房工作流完成（未导出）")


func guide_mark_host_ok(ok: bool) -> void:
	if host:
		host.guide_mark_host_ok(ok)


func phase_label() -> String:
	if host == null:
		return "无核心"
	var p: String = host.guide_phase()
	var map := {
		"host_check": "宿主检查",
		"draw_walls": "画墙",
		"measure_keys": "关键尺寸",
		"place_openings": "门窗洞/垭口",
		"rebuild": "重建",
		"export": "可导出",
	}
	return map.get(p, p)


func blocking_reason() -> String:
	if host == null:
		return "GDExtension 未加载"
	var raw: String = host.guide_blocking_reason()
	var map := {
		"host not on Android whitelist (or experimental)": "宿主未就绪",
		"draw at least 4 walls": "请先画至少四面墙",
		"need ≥2 laser key edges, or typed explicit with ≥2 typed edges": "需要至少两条激光关键边，或已确认的手输边长",
		"place at least one opening": "请放置至少一个门窗洞或垭口",
		"rebuild must succeed before export": "导出前需要重建通过",
	}
	if map.has(raw):
		return str(map[raw])
	return raw


func can_export() -> bool:
	return host != null and host.guide_can_export()


func sceneir_json() -> String:
	if host == null:
		return ""
	return host.sceneir_json()


func list_schemes() -> PackedStringArray:
	var dir := DirAccess.open(schemes_dir())
	var out := PackedStringArray()
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".sceneir.json"):
			out.append(schemes_dir().path_join(name))
		name = dir.get_next()
	dir.list_dir_end()
	return out
