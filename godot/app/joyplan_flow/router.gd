class_name FlowRouter
extends RefCounted
## JoyPlan screen FSM. Video order: home → scale → 2D → 3D → (ruler/dims) → elevation.

const HOME := "res://app/joyplan_flow/home.tscn"
const PROJECTS := "res://app/joyplan_flow/projects.tscn"
const NEW_PLAN := "res://app/joyplan_flow/new_plan.tscn"
const SCALE := "res://app/joyplan_flow/scale_calibrate.tscn"
const GENERATE := "res://app/joyplan_flow/generate_space.tscn"
const FREE_DRAW := "res://app/joyplan_flow/free_draw.tscn"
const AR_SCAN := "res://app/joyplan_flow/ar_scan.tscn"
const EDIT_2D := "res://app/joyplan_flow/edit_2d.tscn"
const EDIT_3D := "res://app/joyplan_flow/edit_3d.tscn"
const ELEVATION := "res://app/joyplan_flow/elevation_index.tscn"

const SCREEN_HOME := "home"
const SCREEN_PROJECTS := "projects"
const SCREEN_NEW_PLAN := "new_plan"
const SCREEN_SCALE := "scale"
const SCREEN_GENERATE := "generate"
const SCREEN_FREE_DRAW := "free_draw"
const SCREEN_AR_SCAN := "ar_scan"
const SCREEN_EDIT_2D := "edit_2d"
const SCREEN_EDIT_3D := "edit_3d"
const SCREEN_ELEVATION := "elevation"


static func go(node: Node, path: String, screen: String = "") -> void:
	if screen != "":
		Session.screen = screen
	node.get_tree().change_scene_to_file(path)


static func home(node: Node) -> void:
	go(node, HOME, SCREEN_HOME)


static func projects(node: Node) -> void:
	go(node, PROJECTS, SCREEN_PROJECTS)


static func new_plan(node: Node) -> void:
	go(node, NEW_PLAN, SCREEN_NEW_PLAN)


static func scale(node: Node) -> void:
	go(node, SCALE, SCREEN_SCALE)


static func generate(node: Node) -> void:
	go(node, GENERATE, SCREEN_GENERATE)


static func free_draw(node: Node) -> void:
	go(node, FREE_DRAW, SCREEN_FREE_DRAW)


static func ar_scan(node: Node) -> void:
	go(node, AR_SCAN, SCREEN_AR_SCAN)


static func edit_2d(node: Node) -> void:
	go(node, EDIT_2D, SCREEN_EDIT_2D)


static func edit_3d(node: Node) -> void:
	go(node, EDIT_3D, SCREEN_EDIT_3D)


static func elevation(node: Node) -> void:
	go(node, ELEVATION, SCREEN_ELEVATION)
