extends Node3D
## Visualization-only lighting / materials. Must not write SceneIR millimetres (I8).
## Tuned for Godot 4 gl_compatibility (mobile APK).

const PRESET_DAY := "day"
const PRESET_WARM := "warm"

var preset: String = PRESET_DAY
var environment_node: WorldEnvironment
var sun: DirectionalLight3D
var fill: OmniLight3D
var lamp: SpotLight3D

var _environment: Environment
var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _hosted_mat: StandardMaterial3D
var _gizmo_mat: StandardMaterial3D
var _gizmo_hot_mat: StandardMaterial3D
var _opening_mats: Dictionary = {}


func _ready() -> void:
	_build()
	apply_preset(PRESET_DAY)


func _build() -> void:
	environment_node = WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.fog_enabled = false
	environment_node.environment = _environment
	add_child(environment_node)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.shadow_bias = 0.06
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)

	fill = OmniLight3D.new()
	fill.name = "InteriorFill"
	fill.omni_range = 14.0
	fill.omni_attenuation = 1.4
	fill.shadow_enabled = false
	fill.position = Vector3(2.0, 2.2, 1.5)
	add_child(fill)

	lamp = SpotLight3D.new()
	lamp.name = "MoodSpot"
	lamp.spot_range = 9.0
	lamp.spot_angle = 48.0
	lamp.shadow_enabled = false
	lamp.position = Vector3(2.0, 2.6, 1.5)
	lamp.rotation_degrees = Vector3(-90, 0, 0)
	add_child(lamp)

	_wall_mat = _pbr(Color(0.90, 0.89, 0.88), 0.88, 0.0)
	_floor_mat = _pbr(Color(0.52, 0.47, 0.41), 0.74, 0.05)
	_hosted_mat = _pbr(Color(0.62, 0.55, 0.44), 0.55, 0.12)
	_gizmo_mat = _unshaded(Color(0.98, 0.82, 0.18))
	_gizmo_hot_mat = _unshaded(Color(1.0, 0.45, 0.12))


func apply_preset(name: String) -> void:
	preset = PRESET_WARM if name == PRESET_WARM else PRESET_DAY
	if preset == PRESET_WARM:
		_apply_warm()
	else:
		_apply_day()


func toggle_preset() -> String:
	apply_preset(PRESET_WARM if preset == PRESET_DAY else PRESET_DAY)
	return preset


func preset_label() -> String:
	return "暖光" if preset == PRESET_WARM else "白天"


func wall_material() -> StandardMaterial3D:
	return _wall_mat


func wall_material_for_kind(kind: String) -> StandardMaterial3D:
	var key := "shear" if Tokens.is_load_bearing_kind(kind) else "masonry"
	if _opening_mats.has("wall_%s" % key):
		return _opening_mats["wall_%s" % key]
	var mat := _pbr(Color(0.90, 0.72, 0.62), 0.86, 0.0) if key == "shear" else _wall_mat
	_opening_mats["wall_%s" % key] = mat
	return mat


func floor_material() -> StandardMaterial3D:
	return _floor_mat


func hosted_material() -> StandardMaterial3D:
	return _hosted_mat


func gizmo_material(hot: bool = false) -> StandardMaterial3D:
	return _gizmo_hot_mat if hot else _gizmo_mat


func opening_material(kind: String, selected: bool) -> StandardMaterial3D:
	var key := "%s_%s" % [kind, "on" if selected else "off"]
	if _opening_mats.has(key):
		return _opening_mats[key]
	var color := Color(0.22, 0.58, 0.28)
	if kind == "window":
		color = Color(0.18, 0.48, 0.78)
	elif kind == "archway":
		color = Color(0.52, 0.22, 0.68)
	var mat := _pbr(color, 0.42 if kind == "window" else 0.62, 0.08 if kind == "window" else 0.02)
	if selected:
		mat.emission_enabled = true
		mat.emission = color.lightened(0.2)
		mat.emission_energy_multiplier = 0.45
	_opening_mats[key] = mat
	return mat


func _apply_day() -> void:
	_environment.background_color = Color(0.96, 0.93, 0.94)
	_environment.ambient_light_color = Color(0.94, 0.92, 0.93)
	_environment.ambient_light_energy = 0.42
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.light_energy = 1.15
	sun.rotation_degrees = Vector3(-58, 38, 0)
	sun.visible = true
	fill.light_color = Color(0.90, 0.93, 1.0)
	fill.light_energy = 0.22
	lamp.visible = false


func _apply_warm() -> void:
	_environment.background_color = Color(0.16, 0.10, 0.07)
	_environment.ambient_light_color = Color(0.78, 0.52, 0.32)
	_environment.ambient_light_energy = 0.28
	sun.light_color = Color(1.0, 0.70, 0.42)
	sun.light_energy = 0.48
	sun.rotation_degrees = Vector3(-42, 18, 0)
	sun.visible = true
	fill.light_color = Color(1.0, 0.76, 0.48)
	fill.light_energy = 0.85
	lamp.visible = true
	lamp.light_color = Color(1.0, 0.80, 0.52)
	lamp.light_energy = 1.05


func _pbr(albedo: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = metallic
	m.specular_mode = StandardMaterial3D.SPECULAR_SCHLICK_GGX
	return m


func _unshaded(albedo: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = albedo
	return m
