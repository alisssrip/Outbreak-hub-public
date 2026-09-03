class_name UserSearchPanel
extends Control

@export var user_filter_field : LineEdit
@export var user_filter_search_btn : TextureButton
@export var user_filter_user_btn : Button
@export var user_search_control : Control

signal user_filter_changed(query: String)
signal user_canceled()

func _ready() -> void:
	user_filter_field.text_submitted.connect(_on_user_filter_submitted)
	user_filter_user_btn.pressed.connect(func(): _switch_panel(true))
	user_filter_search_btn.pressed.connect(func(): _on_user_filter_submitted(user_filter_field.text))
	_switch_panel(true)


func _on_user_filter_submitted(text: String) -> void:
	user_filter_changed.emit(text)

func _on_cancel() -> void:
	_switch_panel(true)


func _switch_panel(friend_panel: bool) -> void:
	if friend_panel:
		user_search_control.hide()
		user_filter_field.text = ""
		user_canceled.emit()
	else:
		user_search_control.show()
		user_filter_field.grab_focus()