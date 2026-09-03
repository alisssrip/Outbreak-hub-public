class_name UserCardController
extends Node

@export_category("References")
@export var user_card_ui : UserUISystem
@export var user_name : String
@export var current_room : String
@export var current_level : String
@export var current_status : USER_STATUS

func _set_name(name: String) -> void:
	user_name = name
	user_card_ui.SetName(name)
	return
func _set_shader_status(status : USER_STATUS) -> void:
	current_status = status
	user_card_ui._change_active_status(current_status)
	return
	
func _set_value_infection(value: float) -> void:
	user_card_ui._change_text_infection_label(str(value));
	return
func _set_character(index: int) -> void:
	user_card_ui._set_character(index)

func _set_in_game_status(place: String) -> void:
	user_card_ui._change_text_in_game_status_label(place);
	return


enum USER_STATUS { ONLINE, AFK, BUSY, IN_GAME, OFFLINE }
	
