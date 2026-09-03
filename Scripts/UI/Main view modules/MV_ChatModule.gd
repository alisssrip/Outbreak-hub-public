class_name MV_ChatModule
extends MV_BaseModule

@export var chat : ChatManager

var _pending_private_id : int = -1
var open : bool
signal global_message_background()

func _ready() -> void:
	chat.view_friend_profile_requested.connect(_on_view_profile)
	chat.remove_friend_requested.connect(_on_remove_friend)
	chat.global_message_background.connect(_on_global_message_background)

func _on_global_message_background(data: Dictionary) -> void:
	global_message_background.emit()
	return

func initState(hndlr : MainViewComponentSystem) -> MV_BaseModule:
	ctx = hndlr
	return self

func startState() -> void:
	open = true
	_open_window()
	open_a_chat()

func open_a_chat() -> void:
	if _pending_private_id != -1:
		_do_open_private(_pending_private_id)
		_pending_private_id = -1
	else:
		chat.open_global()

func exitState() -> void:
	open = false
	_close_window()

func open_private(friend_id: int) -> void:
	_pending_private_id = friend_id
	if open: open_a_chat()

func _do_open_private(friend_id: int) -> void:
	var data : Dictionary = RpcModules.user_store.get_user(friend_id)
	chat.open_private(friend_id, str(data.get("nickname", "")))

func _open_window() -> void:
	window_panel.show()

func _close_window() -> void:
	window_panel.hide()

func _global_btn_pressed() -> void:
	chat.open_global()

func _on_view_profile(user_id: int) -> void:
	ctx._open_profile_user(user_id)

func _on_remove_friend(friend_id: int) -> void:
	RpcModules.friend.remove(friend_id)
	chat.open_global()