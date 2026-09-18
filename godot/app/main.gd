extends Control
## Product entry: boot the JoyPlan flow. Legacy workbench is under app/_legacy/.

func _ready() -> void:
	get_tree().change_scene_to_file("res://app/joyplan_flow/home.tscn")
