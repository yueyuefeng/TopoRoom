class_name FlowRouter
extends RefCounted
## JoyPlan screen FSM. Video order: home → scale → 2D → 3D → (ruler/dims) → elevation.

const HOME := "res://app/joyplan_flow/home.tscn"
const SCALE := "res://app/joyplan_flow/scale_calibrate.tscn"
const EDIT_2D := "res://app/joyplan_flow/edit_2d.tscn"
const EDIT_3D := "res://app/joyplan_flow/edit_3d.tscn"
const ELEVATION := "res://app/joyplan_flow/elevation_index.tscn"

const SCREEN_HOME := "home"
const SCREEN_SCALE := "scale"
const SCREEN_EDIT_2D := "edit_2d"
const SCREEN_EDIT_3D := "edit_3d"
const SCREEN_ELEVATION := "elevation"


static func go(node: Node, path: String, screen: String = "") -> void:
	if screen != "":
		Session.screen = screen
	node.get_tree().change_scene_to_file(path)


static func home(node: Node) -> void:
	go(node, HOME, SCREEN_HOME)


static func scale(node: Node) -> void:
	go(node, SCALE, SCREEN_SCALE)


static func edit_2d(node: Node) -> void:
	go(node, EDIT_2D, SCREEN_EDIT_2D)


static func edit_3d(node: Node) -> void:
	go(node, EDIT_3D, SCREEN_EDIT_3D)


static func elevation(node: Node) -> void:
	go(node, ELEVATION, SCREEN_ELEVATION)
