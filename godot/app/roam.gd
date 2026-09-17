extends Node3D
## Read-only glTF roam. Instances a StatusGate .glb. Does not write SceneIR.

const Lighting := preload("res://app/lighting.gd")

var _yaw := 0.35
var _pitch := -0.55
var _distance := 9.0
var _camera: Camera3D
var _status: Label
var _root: Node3D
var _lighting: Node3D
var _dragging := false
var _glb_path := ""
var _glb_loaded := false


func _ready() -> void:
	_lighting = Lighting.new()
	_lighting.name = "Lighting"
	add_child(_lighting)

	_camera = Camera3D.new()
	_camera.current = true
	add_child(_camera)
	_orbit()

	_root = Node3D.new()
	_root.name = "FloorPlan"
	add_child(_root)
	_load_glb()

	var hud: Dictionary = Studio.attach_hud(self)
	var col: VBoxContainer = hud.column
	var row := Studio.hbox(Tokens.S1)
	row.add_child(Studio.ghost("返回", func(): get_tree().change_scene_to_file("res://app/main.tscn")))
	row.add_child(Studio.chip("3D 编辑", func(): get_tree().change_scene_to_file("res://app/edit_3d.tscn")))
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)
	var light_idx := 0
	if _lighting and _lighting.preset == Lighting.PRESET_WARM:
		light_idx = 1
	row.add_child(Studio.segmented(PackedStringArray(["白天", "暖光"]), light_idx, func(_i: int, name: String):
		_lighting.apply_preset(Lighting.PRESET_WARM if name == "暖光" else Lighting.PRESET_DAY)
		_refresh_status()
	))
	col.add_child(row)
	_status = Studio.label("", Tokens.FONT_BODY, Tokens.TEXT, true)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	col.add_child(Studio.caption("只读漫游 · 节点来自交付 glb，不会写回尺寸。"))


func _load_glb() -> void:
	var path := Session.last_glb_path if Session else ""
	var loaded := false
	if not path.is_empty() and FileAccess.file_exists(path):
		loaded = _append_gltf(path)
	if not loaded:
		# Editor-imported fixture (also read-only).
		if ResourceLoader.exists("res://fixtures/rect-room-door-laser.glb"):
			var packed: Resource = load("res://fixtures/rect-room-door-laser.glb")
			if packed is PackedScene:
				_root.add_child((packed as PackedScene).instantiate())
				loaded = true
				path = "res://fixtures/rect-room-door-laser.glb"
		if not loaded:
			loaded = _append_gltf("res://fixtures/rect-room-door-laser.glb")
			if loaded:
				path = "res://fixtures/rect-room-door-laser.glb"
	_glb_loaded = loaded
	_glb_path = path if loaded else ""
	_refresh_status()


func _refresh_status() -> void:
	if _status == null:
		return
	var light: String = _lighting.preset_label() if _lighting else "—"
	if _glb_loaded:
		_status.text = "灯光 %s · %s" % [light, _glb_path]
	else:
		_status.text = "还没有可漫游的模型。请先在户型图导出（闸门通过后才有 glb）。"


func _append_gltf(path: String) -> bool:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		return false
	var node := doc.generate_scene(state)
	if node == null:
		return false
	_root.add_child(node)
	return true


func _orbit() -> void:
	if _camera == null:
		return
	var target := Vector3(2.0, 1.2, 1.5)
	var offset := Vector3(
		_distance * cos(_pitch) * sin(_yaw),
		_distance * sin(_pitch),
		_distance * cos(_pitch) * cos(_yaw)
	)
	_camera.look_at_from_position(target + offset, target)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = max(3.0, _distance - 0.6)
			_orbit()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = min(24.0, _distance + 0.6)
			_orbit()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * 0.005
		_pitch = clampf(_pitch - mm.relative.y * 0.005, -1.2, -0.08)
		_orbit()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_yaw -= sd.relative.x * 0.005
		_pitch = clampf(_pitch - sd.relative.y * 0.005, -1.2, -0.08)
		_orbit()
