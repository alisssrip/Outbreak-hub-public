class_name UserMiniProfileSystem
extends Node

@export var controller      : UserUISystem
@export var header          : UIMainviewHeaderButtonSystem

var store: Array[CharacterData]

func _ready() -> void:
	controller._on_mini_profile_pressed.connect(_go_to_profile)
	RpcModules.user_store.user_updated.connect(_on_user_updated)
	RpcModules.user_store.ingame_updated.connect(_on_ingame_updated)
	RpcModules.user.profile_loaded.connect(_on_profile_loaded)
	store = LauncherController.instance.character.store

func _on_profile_loaded() -> void:
	var uid = RpcModules.user.user_id
	controller._set_name(RpcModules.user.nickname)
	if not RpcModules.user.avatar_url.is_empty():
		var full_url := Endpoints.resource_base() + RpcModules.user.avatar_url
		NetworkHandler.profile.load_image(full_url, func(texture):
			controller._set_avatar(texture)
		)
	_apply(uid)

func _apply(uid: int) -> void:
	var user = RpcModules.user_store.get_user(uid)
	var ingame = RpcModules.user_store.get_ingame(uid)
	var phase = str(user.get("phase", "online"))
	var favChar = RpcModules.user.char_fav
	controller._change_active_status(IngameStatusFormat.phase_to_index(phase))
	controller._set_shader(controller._mat)
	controller._change_text_in_game_status_label(IngameStatusFormat.in_game_status(user, ingame))
	controller._change_text_infection_label(IngameStatusFormat.infection_text(user, ingame, true))
	if phase == "in_game":
		var current_char := RpcModules.ingame._status.get_character_name_without_costume()
		for data in store:
			if current_char == data.character_name:
				controller._set_character(data.status)
			break
	else:
		for data in store:
			if favChar == data.character_name:
				controller._set_character(data.status)
				break

	

func _on_user_updated(uid: int, _fields: Array) -> void:
	if uid != RpcModules.user.user_id: return
	_apply(uid)

func _on_ingame_updated(uid: int) -> void:
	if uid != RpcModules.user.user_id: return
	_apply(uid)

func _go_to_profile() -> void:
	header._press_btn("Profile", true)
