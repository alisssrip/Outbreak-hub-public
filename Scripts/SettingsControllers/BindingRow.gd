extends SettingRow
class_name BindingRow

@export var button: Button
@export var default_joy_input: String

var _listening := false
var _binding := ""

const KEY_TO_PCSX2 := {
	KEY_ENTER: "Return", KEY_BACKSPACE: "Backspace", KEY_TAB: "Tab",
	KEY_ESCAPE: "Escape", KEY_SPACE: "Space", KEY_CTRL: "Control",
	KEY_SHIFT: "Shift", KEY_ALT: "Alt", KEY_CAPSLOCK: "CapsLock",
	KEY_DELETE: "Delete", KEY_INSERT: "Insert", KEY_HOME: "Home",
	KEY_END: "End", KEY_PAGEUP: "PageUp", KEY_PAGEDOWN: "PageDown",
	KEY_UP: "Up", KEY_DOWN: "Down", KEY_LEFT: "Left", KEY_RIGHT: "Right",
	KEY_APOSTROPHE: "Apostrophe", KEY_BAR: "Bar", KEY_LESS: "Less",
	KEY_PERIOD: "Period", KEY_PLUS: "Plus", KEY_MINUS: "Minus",
	KEY_F1: "F1", KEY_F2: "F2", KEY_F3: "F3", KEY_F4: "F4",
	KEY_F5: "F5", KEY_F6: "F6", KEY_F7: "F7", KEY_F8: "F8",
	KEY_F9: "F9", KEY_F10: "F10", KEY_F11: "F11", KEY_F12: "F12",
	KEY_KP_0: "Numpad0", KEY_KP_1: "Numpad1", KEY_KP_2: "Numpad2",
	KEY_KP_3: "Numpad3", KEY_KP_4: "Numpad4", KEY_KP_5: "Numpad5",
	KEY_KP_6: "Numpad6", KEY_KP_7: "Numpad7", KEY_KP_8: "Numpad8",
	KEY_KP_9: "Numpad9", KEY_KP_ADD: "NumpadPlus",
	KEY_KP_SUBTRACT: "NumpadMinus", KEY_KP_MULTIPLY: "NumpadAsterisk",
	KEY_KP_DIVIDE: "NumpadSlash", KEY_KP_PERIOD: "NumpadPeriod",
}

const JOY_BUTTON_TO_PCSX2 := {
	JOY_BUTTON_A: "FaceSouth", JOY_BUTTON_B: "FaceEast",
	JOY_BUTTON_X: "FaceWest", JOY_BUTTON_Y: "FaceNorth",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_START: "Start",
	JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_LEFT_SHOULDER: "LeftShoulder",
	JOY_BUTTON_RIGHT_SHOULDER: "RightShoulder",
	JOY_BUTTON_LEFT_STICK: "LeftStick", JOY_BUTTON_RIGHT_STICK: "RightStick",
	JOY_BUTTON_DPAD_UP: "DPadUp", JOY_BUTTON_DPAD_DOWN: "DPadDown",
	JOY_BUTTON_DPAD_LEFT: "DPadLeft", JOY_BUTTON_DPAD_RIGHT: "DPadRight",
}

const JOY_AXIS_TO_PCSX2 := {
	JOY_AXIS_LEFT_X: "LeftX", JOY_AXIS_LEFT_Y: "LeftY",
	JOY_AXIS_RIGHT_X: "RightX", JOY_AXIS_RIGHT_Y: "RightY",
	JOY_AXIS_TRIGGER_LEFT: "LeftTrigger", JOY_AXIS_TRIGGER_RIGHT: "RightTrigger",
}

func _ready() -> void:
	super()
	button.toggle_mode = true
	button.toggled.connect(_on_toggled)

func _on_toggled(pressed_state: bool) -> void:
	if pressed_state:
		_start_listening()
	else:
		_stop_listening()

func _start_listening() -> void:
	_listening = true
	button.text = tr("PAD_PRESS_KEY")

func _stop_listening() -> void:
	_listening = false
	button.set_pressed_no_signal(false)
	_refresh_label()

func _input(event: InputEvent) -> void:
	if not _listening:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_stop_listening()
			get_viewport().set_input_as_handled()
			return
		var b := _key_to_pcsx2(event.keycode)
		if b == "":
			_reject_unsupported()
		else:
			_apply(b)
	elif event is InputEventJoypadButton and event.pressed:
		var b := _joy_button_to_pcsx2(event.button_index)
		if b == "":
			_reject_unsupported()
		else:
			_apply(b)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		var b := _joy_axis_to_pcsx2(event.axis, event.axis_value)
		if b == "":
			_reject_unsupported()
		else:
			_apply(b)

func _apply(binding: String) -> void:
	_binding = binding
	button.set_meta("binding", binding)
	value_changed.emit(setting_key, binding)
	_stop_listening()
	get_viewport().set_input_as_handled()

func _reject_unsupported() -> void:
	_listening = false
	button.set_pressed_no_signal(false)
	button.text = tr("PAD_UNSUPPORTED")
	get_viewport().set_input_as_handled()

func set_value(value: Variant) -> void:
	_binding = str(value)
	button.set_meta("binding", _binding)
	_refresh_label()

func get_value() -> Variant:
	return _binding

func _refresh_label() -> void:
	button.text = _pretty(_binding) if _binding != "" else tr("PAD_UNBOUND")

func _pretty(binding: String) -> String:
	return binding


func apply_binding(binding: String) -> void:
	set_value(binding)
	value_changed.emit(setting_key, binding)

func _key_to_pcsx2(keycode: int) -> String:
	if KEY_TO_PCSX2.has(keycode):
		return "Keyboard/" + KEY_TO_PCSX2[keycode]
	var s := OS.get_keycode_string(keycode)
	if s.length() == 1 and ((s >= "A" and s <= "Z") or (s >= "0" and s <= "9")):
		return "Keyboard/" + s
	return ""

func _joy_button_to_pcsx2(button_index: int) -> String:
	if not JOY_BUTTON_TO_PCSX2.has(button_index):
		return ""
	return "SDL-0/" + JOY_BUTTON_TO_PCSX2[button_index]

func _joy_axis_to_pcsx2(axis: int, value: float) -> String:
	if not JOY_AXIS_TO_PCSX2.has(axis):
		return ""
	var n: String = JOY_AXIS_TO_PCSX2[axis]
	if axis == JOY_AXIS_TRIGGER_LEFT or axis == JOY_AXIS_TRIGGER_RIGHT:
		return "SDL-0/+" + n
	var s := "-" if value > 0.0 else "+"
	return "SDL-0/" + s + n
