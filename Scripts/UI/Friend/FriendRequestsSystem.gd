class_name FriendRequestsSystem
extends Node

@export var request_card_prefab : PackedScene
@export var requests_container  : VBoxContainer
@export var line : Label
var elements : Array[FriendRequestCard] = []

func _ready() -> void:
	RpcModules.friend_requests.requests_loaded.connect(_on_loaded)
	RpcModules.friend_requests.request_added.connect(_on_added)
	RpcModules.friend_requests.request_removed.connect(_on_removed)

func _on_loaded(_ids: Array) -> void:
	_rebuild()

func _on_added(_uid: int) -> void:
	_rebuild()

func _on_removed(uid: int) -> void:
	for child in requests_container.get_children():
		if child is FriendRequestCard and child._from_id == uid:
			child.queue_free()
			return

func _rebuild() -> void:
	for child in requests_container.get_children():
		child.free()
	elements.clear()
	line.hide()
	for uid in RpcModules.friend_requests.pending:
		var card : FriendRequestCard = request_card_prefab.instantiate()
		requests_container.add_child(card)
		card.setup(int(uid))
		elements.append(card)
		line.show()