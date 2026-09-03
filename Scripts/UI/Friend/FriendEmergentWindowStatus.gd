class_name FriendEmergentWindowStatus
extends Control

@export var controller : UserUISystem
@export var character : TextureRect
var _hiding : bool = false
var current_friend_id : int = -1
var _fade_tween : Tween
var store: Array[CharacterData]

func _ready() -> void:
	hide()
	RpcModules.user_store.user_updated.connect(_on_user_updated)
	RpcModules.user_store.ingame_updated.connect(_on_ingame_updated)
	store = LauncherController.instance.character.store

func show_for(friend_id: int, card_position: Vector2) -> void:
	_hiding = false
	current_friend_id = friend_id
	var data := RpcModules.user_store.get_user(friend_id)
	if data.is_empty(): return
	controller._set_name(str(data.get("nickname", "")))
	_apply(friend_id)
	var avatar := RpcModules.user_store.get_avatar(friend_id)
	if avatar != null:
		controller._set_avatar(avatar)
	var target_pos := Vector2(card_position.x - size.x - 8, card_position.y)
	if _fade_tween: _fade_tween.kill()
	global_position = target_pos
	modulate.a = 0.0
	show()
	if _hiding: return
	_fade_tween = create_tween()
	_fade_tween.tween_interval(0.016)
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.15)

func hide_animated() -> void:
	_hiding = true
	if _fade_tween: _fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_fade_tween.tween_callback(func():
		if _hiding:
			hide()
	)

func _apply(uid: int) -> void:
	var user := RpcModules.user_store.get_user(uid)
	var ingame := RpcModules.user_store.get_ingame(uid)
	var phase := str(user.get("phase", "offline"))
	var favChar = RpcModules.user.char_fav
	controller._change_active_status(IngameStatusFormat.phase_to_index(phase))
	controller._set_shader(controller._mat)
	controller._change_text_in_game_status_label(IngameStatusFormat.in_game_status(user, ingame))
	controller._change_text_infection_label(IngameStatusFormat.infection_text(user, ingame))
	if phase == "in_game":
		for data in store:
			if RpcModules.ingame._status.get_character_name_without_costume() == data.character_name:
				Log.d(data.character_name)
				controller._set_character(data.status)
				break
	else:
		for data in store:
			if favChar == data.character_name:
				controller._set_character(data.status)
				break
func _on_user_updated(uid: int, _fields: Array) -> void:
	if uid != current_friend_id or not visible: return
	_apply(uid)

func _on_ingame_updated(uid: int) -> void:
	if uid != current_friend_id or not visible: return
	_apply(uid)
func _update_character(index: int) -> void:
	character.texture = LauncherController.instance.character.store[index].status
	return