class_name GameResultsDobleField

extends Node


@export var field1 : Label
@export var field2: Label


func set_field_color(field: int, color: Color) -> void:
    match field:
        1: _set_field_color(field1, color)
        2: _set_field_color(field2, color)

func set_field_text(field: int, text: String) -> void:
    match field:
        1: _set_field_text(field1, text)
        2: _set_field_text(field2, text)

func _set_field_color(field: Label, color: Color) -> void:
    field.add_theme_color_override("font_color", color)

func _set_field_text(field: Label, text: String) -> void:
    field.text = text