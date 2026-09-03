extends Node
class_name SettingRow

signal value_changed(key: String, value: Variant)

@export var setting_key: String
@export var default_value: int = 0
@export var title_label: Label
@export var description_label: RichTextLabel

@export var title: String
@export var description: String

func _ready() -> void:
	if title_label:
		title_label.text = tr(title)
	if description_label:
		description_label.text = tr(description)
		description_label.visible = description != ""

func set_value(value: Variant) -> void:
	pass

func get_value() -> Variant:
	return default_value