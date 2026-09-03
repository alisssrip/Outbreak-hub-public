extends SettingRow
class_name ActionRow

signal action_triggered(key: String)

@export var button: Button

func _ready() -> void:
	super()
	button.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	action_triggered.emit(setting_key)