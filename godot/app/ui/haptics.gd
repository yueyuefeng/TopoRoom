class_name Haptics
extends Object
## Best-effort Android vibration. No-op on desktop / when the OS ignores it.

static func snap() -> void:
	_pulse(14)


static func drop() -> void:
	_pulse(28)


static func warn() -> void:
	_pulse(40)


static func _pulse(ms: int) -> void:
	if not OS.has_feature("mobile") and OS.get_name() != "Android":
		return
	Input.vibrate_handheld(ms)
