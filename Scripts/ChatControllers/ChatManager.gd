class_name ChatManager
extends Node

signal private_message_in_focus(from_id: int, data: Dictionary)
signal private_message_background(from_id: int, data: Dictionary)
signal private_opened(friend_id: int)
signal global_message_in_focus(data: Dictionary)
signal global_message_background(data: Dictionary)
signal view_friend_profile_requested(user_id: int)
signal remove_friend_requested(friend_id: int)

@export var global_chat  : ChatController
@export var private_chat : ChatController

var _private_id : int = -1

func _ready() -> void:
	RpcModules.global_chat.global_message_received.connect(_on_global_message)
	RpcModules.global_chat.global_message_pushed.connect(_on_global_message_pushed)
	RpcModules.private_chat.message_received.connect(_on_private_message)
	RpcModules.private_chat.message_pushed.connect(_on_private_message_pushed)

	global_chat.message_sent.connect(_on_global_sent)
	global_chat.load_more_requested.connect(_on_global_load_more)
	private_chat.message_sent.connect(_on_private_sent)
	private_chat.load_more_requested.connect(_on_private_load_more)
	global_chat.on_global_button_pressed.connect(open_global)
	private_chat.on_global_button_pressed.connect(open_global)
	private_chat.on_view_profile_pressed.connect(_on_view_profile_pressed)
	private_chat.on_remove_friend_pressed.connect(_on_remove_friend_pressed)
	global_chat.message_user_clicked.connect(_on_message_user_clicked)
	private_chat.message_user_clicked.connect(_on_message_user_clicked)
	global_chat.set_friend_actions_visible(false)

	if RpcClient.is_connected_to_server():
		open_global()
	else:
		RpcClient.connected.connect(func():
			open_global()
		, CONNECT_ONE_SHOT)
	RpcModules.friend.friend_removed.connect(_on_friend_removed)

func open_private(friend_id: int, friend_name: String) -> void:
	_private_id = friend_id
	private_opened.emit(friend_id)
	private_chat.clear_chat()
	private_chat.set_title(friend_name)
	private_chat.set_friend_actions_visible(true)
	private_chat.hide_load_more_button()
	RpcModules.private_chat.history_loaded.connect(func(has_more: bool):
		if has_more:
			private_chat.show_load_more_button()
		else:
			private_chat.hide_load_more_button()
	, CONNECT_ONE_SHOT)
	RpcModules.private_chat.get_history(friend_id, true)
	global_chat.hide()
	private_chat.show()


func _on_friend_removed(id: int) -> void:
	if _private_id == id:
		open_global()
	return

func open_global() -> void:
	_private_id = -1
	global_chat.clear_chat()
	global_chat.set_title(tr("CHAT_GLOBAL_TITLE"))
	global_chat.hide_load_more_button()
	RpcModules.global_chat.history_loaded.connect(func(has_more: bool):
		if has_more:
			global_chat.show_load_more_button()
		else:
			global_chat.hide_load_more_button()
	, CONNECT_ONE_SHOT)
	RpcModules.global_chat.get_history(true)
	global_chat.show()
	private_chat.hide()

func is_viewing_private(friend_id: int) -> bool:
	return _private_id == friend_id and private_chat.main_panel.is_visible_in_tree()

func _on_global_sent(text: String) -> void:
	RpcModules.global_chat.send_global(text)

func _on_global_load_more() -> void:
	global_chat.set_loading_more(true)
	RpcModules.global_chat.history_loaded.connect(func(has_more: bool):
		global_chat.set_loading_more(false)
		if not has_more:
			global_chat.hide_load_more_button()
	, CONNECT_ONE_SHOT)
	RpcModules.global_chat.load_more()

func _on_private_sent(text: String) -> void:
	if _private_id != -1:
		RpcModules.private_chat.send(_private_id, text)

func _on_private_load_more() -> void:
	private_chat.set_loading_more(true)
	RpcModules.private_chat.history_loaded.connect(func(has_more: bool):
		private_chat.set_loading_more(false)
		if not has_more:
			private_chat.hide_load_more_button()
	, CONNECT_ONE_SHOT)
	RpcModules.private_chat.load_more()

func _on_global_message_pushed(data: Dictionary) -> void:
	if int(data.get("userId", 0)) == RpcModules.user.user_id:
		return
	AudioController.play("Move-1")

func _on_private_message_pushed(from_id: int, data: Dictionary) -> void:
	if data.get("isOwn", false) or from_id == RpcModules.user.user_id:
		return
	AudioController.play("Move-1")

func _on_global_message(data: Dictionary) -> void:
	if global_chat.main_panel.is_visible_in_tree():
		global_message_in_focus.emit(data)
	else:
		global_message_background.emit(data)
	global_chat._on_message_received({
		"user_name": data.get("nickname", ""),
		"date":      ChatController._format_timestamp(str(data.get("timestamp", ""))),
		"msg":       data.get("content", ""),
		"user_id":   int(data.get("userId", 0)),
		"timestamp": str(data.get("timestamp", ""))
	})

func _on_private_message(from_id: int, data: Dictionary) -> void:
	if data.get("isOwn", false):
		_render_private(from_id, data)
		return
	if is_viewing_private(from_id):
		private_message_in_focus.emit(from_id, data)
	else:
		private_message_background.emit(from_id, data)
	if from_id != _private_id:
		return
	_render_private(from_id, data)

func _render_private(from_id: int, data: Dictionary) -> void:
	var user_data : Dictionary = RpcModules.user_store.get_user(from_id)
	private_chat._on_message_received({
		"user_name": str(user_data.get("nickname", data.get("nickname", ""))),
		"date":      ChatController._format_timestamp(str(data.get("timestamp", ""))),
		"msg":       str(data.get("content", "")),
		"user_id":   from_id,
		"timestamp": str(data.get("timestamp", ""))
	})

func _on_view_profile_pressed() -> void:
	if _private_id == -1: return
	view_friend_profile_requested.emit(_private_id)

func _on_remove_friend_pressed() -> void:
	if _private_id == -1: return
	Popups_Controller.instance.show_confirm(tr("POPUP_REMOVE_FRIEND"), func() -> void: remove_friend_requested.emit(_private_id))



func _on_message_user_clicked(user_id: int) -> void:
	if user_id == RpcModules.user.user_id: return
	view_friend_profile_requested.emit(user_id)