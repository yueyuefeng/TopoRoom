extends Control
## 2/2 生成空间: preview the imported plan, 确定 enters the 2D editor.

const PlanCanvas := preload("res://app/plan_canvas.gd")
const Snackbar := preload("res://app/ui/snackbar.gd")
const JoyplanChrome := preload("res://app/joyplan_flow/joyplan_chrome.gd")

var _canvas: PlanCanvas
var _snack: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Studio.apply_to(self)
	Session.screen = FlowRouter.SCREEN_GENERATE

	var bg := ColorRect.new()
	bg.color = Color("F4F4F4")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_canvas = PlanCanvas.new()
	_canvas.set_anchors_preset(PRESET_FULL_RECT)
	_canvas.offset_top = 56
	_canvas.show_chrome = false
	_canvas.joyplan_look = true
	_canvas.interactive = false
	add_child(_canvas)
	var photo := Session.last_import_path
	if photo.is_empty():
		photo = Session.last_import_uri
	if photo.is_empty():
		photo = ProjectSettings.globalize_path("res://fixtures/apt-plan-user-01.png")
	_canvas.load_photo(photo)
	_canvas.set_sceneir_json(Session.sceneir_json())

	add_child(JoyplanChrome.step_bar(
		"2/2 生成空间",
		"确定",
		func(): FlowRouter.scale(self),
		func(): _confirm()
	))

	_snack = Snackbar.new()
	_snack.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_snack.offset_left = 24
	_snack.offset_right = -24
	_snack.offset_top = -88
	_snack.offset_bottom = -28
	add_child(_snack)


func _confirm() -> void:
	if Session.sceneir_json().find("wall_") < 0:
		var uri := Session.last_import_uri
		if uri.is_empty():
			uri = Session.last_import_path
		var err := Session.import_photo_vision(uri, Session.last_scale_mm_per_px)
		if err != "" and Session.has_core():
			Session.import_photo_fake(uri if not uri.is_empty() else "fixture:photo")
	FlowRouter.edit_2d(self)
