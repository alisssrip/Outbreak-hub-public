class_name FriendRequestCard
extends Control

@export var name_label   : Label
@export var icon_rect    : TextureRect
@export var accept_btn   : Button
@export var decline_btn  : Button

var _from_id : int = 0

func _ready() -> void:
	accept_btn.pressed.connect(_on_accept)
	decline_btn.pressed.connect(_on_decline)

func setup(from_id: int) -> void:
	_from_id = from_id
	_refresh()
	RpcModules.user_store.user_updated.connect(_on_user_updated)

func _refresh() -> void:
	var data : Dictionary = RpcModules.user_store.get_user(_from_id)
	if data.is_empty(): return
	name_label.text = str(data.get("nickname", ""))
	var texture := RpcModules.user_store.get_avatar(_from_id)
	if texture != null:
		icon_rect.texture = texture

func _on_user_updated(uid: int, _fields: Array) -> void:
	if uid != _from_id: return
	_refresh()

func _on_accept() -> void:
	accept_btn.disabled = true
	decline_btn.disabled = true
	RpcModules.friend_requests.accept(_from_id)

func _on_decline() -> void:
	accept_btn.disabled = true
	decline_btn.disabled = true
	RpcModules.friend_requests.decline(_from_id)