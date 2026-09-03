extends SettingRow
class_name CheckboxRow

@export var check: CheckButton

func _ready() -> void:
	super()
	check.toggled.connect(_on_toggled)

func _on_toggled(pressed_state: bool) -> void:
	value_changed.emit(setting_key, get_value())

func set_value(value: Variant) -> void:
	check.set_pressed_no_signal(value == 1)

func get_value() -> Variant:
	return 1 if check.button_pressed else 0