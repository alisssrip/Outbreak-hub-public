class_name FriendSearchPanel
extends Control

@export var friend_filter_field : LineEdit
@export var friend_filter_search_btn : TextureButton
@export var friend_filter_user_btn : TextureButton
@export var user_search_control : UserSearchPanel

signal friend_filter_changed(query: String)
signal user_search_mode_entered()
signal search_cancelled()

func _ready() -> void:
	friend_filter_field.text_changed.connect(_on_friend_filter_text_changed)
	friend_filter_field.text_submitted.connect(_on_friend_filter_submitted)
	friend_filter_user_btn.pressed.connect(_on_user_btn_pressed)
	_switch_panel(true)

func _on_friend_filter_text_changed(text: String) -> void:
	friend_filter_changed.emit(text)

func _on_friend_filter_submitted(text: String) -> void:
	friend_filter_changed.emit(text)

func _on_user_btn_pressed() -> void:
	_switch_panel(false)
	user_search_mode_entered.emit()

func _on_cancel() -> void:
	_switch_panel(true)
	if friend_filter_field.text.is_empty():
		search_cancelled.emit()
	else:
		friend_filter_changed.emit(friend_filter_field.text)


func _switch_panel(friend_panel: bool) -> void:
	if friend_panel:
		user_search_control._switch_panel(true)
	else:
		user_search_control._switch_panel(false)
