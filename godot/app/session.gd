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
var screen: String = "home"  # home | guide

func _ready() -> void:
	if ClassDB.class_exists("TopoRoomHost"):
		host = ClassDB.instantiate("TopoRoomHost")
		host.create_document("doc_godot")
		opening_serial = 0
		key_serial = 0
		guide_mark_host_ok(true)
		auto_save()
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
	_log(msg)
	emit_signal("document_changed")
	return ""


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
	auto_save()
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
	var label := {"door": "门洞", "window": "窗洞", "archway": "垭口"}.get(kind, kind)
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
	auto_save()
	return _result(d, "层高 %smm" % str(height_mm))


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
	return host.guide_blocking_reason()


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
