class_name UserListSystem
extends Node

@export var container : Control
@export var user_card_prefab : PackedScene
@export var user_container  : VBoxContainer
@export var main_view          : MainViewComponentSystem
@export var loading_spinner : LoadingSpinner
@export var empty_search_label : Label
@export var search_panel       : UserSearchPanel

enum Mode { FRIENDS, SEARCH_RESULTS }

var _mode : Mode = Mode.FRIENDS
var _visible_ids : Array = []
var _search_result_ids : Array = []
var _last_filter : String = ""

func _ready() -> void:
	RpcModules.user_store.users_bulk_loaded.connect(_on_bulk_loaded)
	RpcModules.user_search.search_started.connect(_on_search_started)
	RpcModules.user_search.search_completed.connect(_on_search_completed)
	RpcModules.user_search.search_failed.connect(_on_search_failed)
	search_panel.user_filter_changed.connect(_on_user_search_requested)
	search_panel.user_filter_changed.connect(_filter_friends)
	search_panel.user_canceled.connect(emptyContainer)



func _on_search_started() -> void:
	loading_spinner.start()
	loading_spinner.get_parent().show()
	empty_search_label.hide()

func _on_search_completed(ids: Array) -> void:
	loading_spinner.stop()
	loading_spinner.get_parent().hide()
	_search_result_ids = ids
	_visible_ids = ids
	if _search_result_ids.size() <= 0: empty_search_label.show()
	_rebuild()


func emptyContainer() -> void:
	for child in user_container.get_children():
		user_container.remove_child(child)
		child.queue_free()

func _rebuild() -> void:
	emptyContainer()
	for uid in _visible_ids:
		_add_card(int(uid))

func _on_search_failed() -> void:
	loading_spinner.stop()


func _on_bulk_loaded(_ids: Array) -> void:
	if _mode != Mode.FRIENDS: return
	_visible_ids = _filter_friends(_last_filter)

func _on_user_search_requested(query: String) -> void:
	RpcModules.user_search.search(query)


func _filter_friends(query: String) -> Array:
	var q := query.to_lower().strip_edges()
	if q.is_empty():
		return RpcModules.friend.list.keys()
	var matches : Array = []
	for uid in RpcModules.friend.list:
		var data : Dictionary = RpcModules.user_store.get_user(int(uid))
		var nick : String = str(data.get("nickname", "")).to_lower()
		if nick.contains(q):
			matches.append(int(uid))
	return matches


func _add_card(user_id: int) -> void:
	var card : UserSearchCard = user_card_prefab.instantiate()
	user_container.add_child(card)
	card.setup(user_id)
	card.clicked.connect(_on_card_clicked)


func _on_card_clicked(user_id: int) -> void:
	_show_user_profile(user_id)
	search_panel._switch_panel(true)

func _show_user_profile(user_id: int) -> void:
	main_view._open_profile_user(user_id)
