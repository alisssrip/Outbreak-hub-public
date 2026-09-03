class_name UserSearchCard
extends Control

@export var name_label    : Label
@export var icon_rect     : TextureRect
@export var click_button  : Button

var _friend_id   : int = 0

signal clicked(friend_id: int)
signal hovered(friend_id: int, card_position: Vector2)
signal unhovered

func _ready() -> void:
	click_button.mouse_entered.connect(_on_mouse_entered)
	click_button.mouse_exited.connect(_on_mouse_exited)
	click_button.pressed.connect(_on_pressed)

func setup(user_id: int) -> void:
	_friend_id = user_id
	_refresh()
	RpcModules.user_store.user_updated.connect(_on_user_updated)

func _refresh() -> void:
	var data : Dictionary = RpcModules.user_store.get_user(_friend_id)
	if data.is_empty(): return
	name_label.text = str(data.get("nickname", ""))
	var texture = RpcModules.user_store.get_avatar(_friend_id)
	if texture != null:
		icon_rect.texture = texture


func _on_user_updated(uid: int, _fields: Array) -> void:
	if uid != _friend_id: return
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(_friend_id)

func _on_pressed() -> void:
	clicked.emit(_friend_id)

func _on_mouse_entered() -> void:
	hovered.emit(_friend_id, global_position)

func _on_mouse_exited() -> void:
	unhovered.emit()
