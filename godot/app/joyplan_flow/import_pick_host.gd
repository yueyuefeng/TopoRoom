extends Node
## Owns MediaPicker across 选择户型图 so Android Intents survive modal teardown.

signal imported(path: String)
signal failed(message: String)

const PickModal := preload("res://app/joyplan_flow/pick_source_modal.gd")
const MediaPickerScript := preload("res://app/media_picker.gd")

var _modal: Control
var _picker: Node


func _ready() -> void:
	_picker = MediaPickerScript.new()
	_picker.image_ready.connect(_on_path)
	_picker.failed.connect(_on_fail)
	_picker.cancelled.connect(func(): _on_fail("已取消，可改用示例户型"))
	add_child(_picker)


func open() -> void:
	if _modal and is_instance_valid(_modal):
		_modal.queue_free()
	var parent := get_parent() as Node
	if parent == null:
		return
	_modal = PickModal.new()
	_modal.gallery_pressed.connect(func():
		if _picker:
			_picker.pick_gallery()
	)
	_modal.camera_pressed.connect(func():
		if _picker:
			_picker.capture_photo()
	)
	_modal.sample_picked.connect(_on_path)
	parent.add_child(_modal)


func _on_path(path: String) -> void:
	imported.emit(path)


func _on_fail(msg: String) -> void:
	var text := msg if not msg.is_empty() else "打开相机或相册失败"
	if _modal and is_instance_valid(_modal) and _modal.has_method("show_toast"):
		_modal.busy = false
		_modal.show_toast(text + " · 可改用示例户型")
		return
	failed.emit(text)
