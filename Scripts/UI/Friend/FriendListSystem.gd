class_name FriendListSystem
extends Node

@export var friend_card_prefab : PackedScene
@export var friends_container  : VBoxContainer
@export var emergent_window    : FriendEmergentWindowStatus
@export var main_view          : MainViewComponentSystem
@export var chat_manager       : ChatManager
@export var loading_spinner : LoadingSpinner
@export var empty_friends_label : Label

enum Mode { FRIENDS, SEARCH_RESULTS }

var _mode : Mode = Mode.FRIENDS
var _visible_ids : Array = []
var _search_result_ids : Array = []
var _last_filter : String = ""

func _ready() -> void:
	RpcModules.user_store.users_bulk_loaded.connect(_on_bulk_loaded)
	RpcModules.user_store.user_updated.connect(_on_user_updated)
	chat_manager.private_message_background.connect(_on_private_background)
	chat_manager.private_opened.connect(_on_private_opened)


func _on_search_started() -> void:
	loading_spinner.start()
	loading_spinner.get_parent().show()

func _on_search_completed(ids: Array) -> void:
	loading_spinner.stop()
	loading_spinner.get_parent().hide()
	_mode = Mode.SEARCH_RESULTS
	_search_result_ids = ids
	_visible_ids = ids
	_rebuild()

func _on_search_failed() -> void:
	loading_spinner.stop()

func _on_user_search_mode_entered() -> void:
	_mode = Mode.SEARCH_RESULTS
	_search_result_ids = []
	_visible_ids = []
	_rebuild()

func _on_bulk_loaded(_ids: Array) -> void:
	if _mode != Mode.FRIENDS: return
	_visible_ids = _filter_friends(_last_filter)
	_rebuild()

func _on_user_updated(uid: int, fields: Array) -> void:
	if _mode != Mode.FRIENDS: return
	if not fields.has("phase"): return
	if not _visible_ids.has(uid): return
	_resort_cards()

func _resort_cards() -> void:
	_visible_ids.sort_custom(_compare_friends)
	for i in _visible_ids.size():
		var card := _find_card(int(_visible_ids[i]))
		if card:
			friends_container.move_child(card, i)

func _find_card(uid: int) -> FriendCard:
	for child in friends_container.get_children():
		if child is FriendCard and child._friend_id == uid:
			return child
	return null

func _on_friend_filter_changed(query: String) -> void:
	_mode = Mode.FRIENDS
	_last_filter = query
	_visible_ids = _filter_friends(query)
	_rebuild()


func _on_search_cancelled() -> void:
	_mode = Mode.FRIENDS
	_visible_ids = _filter_friends("")
	_rebuild()

func _filter_friends(query: String) -> Array:
	var q := query.to_lower().strip_edges()
	var matches : Array = []
	for uid in RpcModules.friend.list:
		if not q.is_empty() and not _nickname(int(uid)).contains(q):
			continue
		matches.append(int(uid))
	matches.sort_custom(_compare_friends)
	return matches

func _compare_friends(a: int, b: int) -> bool:
	var rank_a := _status_rank(a)
	var rank_b := _status_rank(b)
	if rank_a != rank_b:
		return rank_a < rank_b
	return _nickname(a) < _nickname(b)

func _status_rank(uid: int) -> int:
	var data : Dictionary = RpcModules.user_store.get_user(uid)
	return IngameStatusFormat.phase_to_index(str(data.get("phase", "offline")))

func _nickname(uid: int) -> String:
	var data : Dictionary = RpcModules.user_store.get_user(uid)
	return str(data.get("nickname", "")).to_lower()


func _enter_friends_mode() -> void:
	_mode = Mode.FRIENDS
	_last_filter = ""
	_visible_ids = _filter_friends("")
	_rebuild()

func _rebuild() -> void:
	for child in friends_container.get_children():
		friends_container.remove_child(child)
		child.queue_free()
	for uid in _visible_ids:
		_add_card(int(uid))
	_update_empty_state()

func _add_card(user_id: int) -> void:
	var card : FriendCard = friend_card_prefab.instantiate()
	friends_container.add_child(card)
	card.setup(user_id)
	card.clicked.connect(_on_card_clicked)
	card.hovered.connect(_on_card_hovered)
	card.unhovered.connect(_on_card_unhovered)

func _on_card_hovered(user_id: int, card_position: Vector2) -> void:
	emergent_window.show_for(user_id, card_position)

func _on_card_unhovered() -> void:
	emergent_window.hide_animated()

func _on_card_clicked(user_id: int) -> void:
	if _mode == Mode.SEARCH_RESULTS:
		_show_user_profile(user_id)
	else:
		main_view._open_private_chat(user_id)

func _show_user_profile(user_id: int) -> void:
	main_view._open_profile_user(user_id)
	_enter_friends_mode.call_deferred()


func _on_private_background(from_id: int, _data: Dictionary) -> void:
	if _mode != Mode.FRIENDS: return
	notify_message(from_id)

func _on_private_opened(user_id: int) -> void:
	for child in friends_container.get_children():
		if child is FriendCard and child._friend_id == user_id:
			child.set_has_message(false)
			return

func notify_message(from_id: int) -> void:
	for child in friends_container.get_children():
		if child is FriendCard and child._friend_id == from_id:
			child.set_has_message(true)
			return

func _update_empty_state() -> void:
	var is_empty := _visible_ids.is_empty()
	empty_friends_label.visible = is_empty and _mode == Mode.FRIENDS
