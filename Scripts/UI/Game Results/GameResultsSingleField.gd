class_name GameResultsSingleField
extends Node

@export var field : Label


func _set_field_color(color: Color) -> void:
    field.add_theme_color_override("font_color", color)

func _set_field_text(text: String) -> void:
    field.text = text
