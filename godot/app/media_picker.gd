class_name MediaPicker
extends Node
## Android system camera + gallery (TopoRoomMedia plugin). Desktop FileDialog fallback.

signal image_ready(path: String)
signal cancelled
signal failed(message: String)

const PLUGIN_NAME := "TopoRoomMedia"

var _plugin: Object
var _dialog: FileDialog
var _pending := "" # camera | gallery
var _busy := false


func _ready() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)
		if not _plugin.is_connected("image_picked", _on_plugin_image):
			_plugin.connect("image_picked", _on_plugin_image)
			_plugin.connect("pick_cancelled", _on_plugin_cancel)
			_plugin.connect("pick_error", _on_plugin_error)
	var tree := get_tree()
	if tree and tree.has_signal("on_request_permissions_result"):
		if not tree.on_request_permissions_result.is_connected(_on_permission):
			tree.on_request_permissions_result.connect(_on_permission)
	_dialog = FileDialog.new()
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; 户型图"])
	_dialog.title = "选择户型图"
	_dialog.use_native_dialog = false
	_dialog.file_selected.connect(_on_file)
	_dialog.canceled.connect(func(): cancelled.emit())
	add_child(_dialog)


func available_on_android() -> bool:
	return _plugin != null


func capture_photo() -> void:
	_pending = "camera"
	if _plugin:
		if not _has_camera_permission():
			_busy = true
			OS.request_permission("android.permission.CAMERA")
			return
		_busy = true
		_plugin.capture_photo()
		return
	_dialog.title = "选择一张户型图（当前环境无系统相机，用文件代替）"
	_dialog.popup_centered_ratio(0.85)


func pick_gallery() -> void:
	_pending = "gallery"
	if _plugin:
		_busy = true
		_plugin.pick_gallery()
		return
	_dialog.title = "从相册导入户型图"
	_dialog.popup_centered_ratio(0.85)


func _has_camera_permission() -> bool:
	var granted: PackedStringArray = OS.get_granted_permissions()
	for p in granted:
		if str(p).ends_with("CAMERA") or str(p) == "CAMERA":
			return true
	return false


func _on_permission(permission: String, granted: bool) -> void:
	if _pending != "camera":
		return
	if not str(permission).ends_with("CAMERA") and str(permission) != "CAMERA":
		return
	if granted:
		if _plugin:
			_busy = true
			_plugin.capture_photo()
		return
	_busy = false
	failed.emit("需要相机权限才能拍照")


func _on_plugin_image(path: String) -> void:
	_busy = false
	if path.is_empty():
		failed.emit("没有收到照片")
		return
	image_ready.emit(path)


func _on_plugin_cancel() -> void:
	_busy = false
	cancelled.emit()


func _on_plugin_error(message: String) -> void:
	_busy = false
	failed.emit(message if not message.is_empty() else "打开相机或相册失败")


func _on_file(path: String) -> void:
	_busy = false
	image_ready.emit(path)
