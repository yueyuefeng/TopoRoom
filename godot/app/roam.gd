extends Node3D
## Read-only glTF roam. Instances a StatusGate .glb. Does not write SceneIR.

var _yaw := 0.35
var _pitch := -0.55
var _distance := 9.0
var _camera: Camera3D
var _status: Label
var _root: Node3D
var _dragging := false


func _ready() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.16, 0.18, 0.20)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.7, 0.72, 0.75)
	environment.ambient_light_energy = 0.55
	env.environment = environment
	add_child(env)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 40, 0)
	light.light_energy = 1.1
	add_child(light)

	_camera = Camera3D.new()
	_camera.current = true
	add_child(_camera)
	_orbit()

	_root = Node3D.new()
	_root.name = "FloorPlan"
	add_child(_root)
	_load_glb()

	var layer := CanvasLayer.new()
	add_child(layer)
	var col := VBoxContainer.new()
	col.offset_left = 16
	col.offset_top = 16
	layer.add_child(col)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(480, 0)
	col.add_child(_status)
	var back := Button.new()
	back.text = "返回户型图"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://app/main.tscn"))
	col.add_child(back)


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
	if _status:
		if loaded:
			_status.text = "只读漫游 · %s\n节点来自 Deliverables/.glb，禁止从三角网写回尺寸。" % path
		else:
			_status.text = "没有可逛的 glb。请先在户型图导出（StatusGate OK）。"


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
