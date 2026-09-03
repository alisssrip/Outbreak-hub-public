class_name FriendCard
extends Control

@export var name_label    : Label
@export var status_label  : Label
@export var icon_rect     : TextureRect
@export var message_bubble: TextureRect
@export var click_button  : Button
@export var status_colors : Array[Color]

var _friend_id   : int = 0
var _has_message : bool = false
var _bubble_tween : Tween

signal clicked(friend_id: int)
signal hovered(friend_id: int, card_position: Vector2)
signal unhovered

func _ready() -> void:
	click_button.mouse_entered.connect(_on_mouse_entered)
	click_button.mouse_exited.connect(_on_mouse_exited)
	click_button.pressed.connect(_on_pressed)
	set_has_message(false)

func setup(user_id: int) -> void:
	_friend_id = user_id
	message_bubble.hide()
	_refresh()
	RpcModules.user_store.user_updated.connect(_on_user_updated)

func _refresh() -> void:
	var data : Dictionary = RpcModules.user_store.get_user(_friend_id)
	if data.is_empty(): return
	name_label.text = str(data.get("nickname", ""))
	_set_status(str(data.get("phase", "offline")))
	var texture = RpcModules.user_store.get_avatar(_friend_id)
	if texture != null:
		icon_rect.texture = texture

func _set_status(phase: String) -> void:
	status_label.text = IngameStatusFormat.status_text(phase)
	status_label.add_theme_color_override("font_color", status_colors[IngameStatusFormat.phase_to_index(phase)])
	icon_rect.modulate = Color("7e7e7e") if phase == "offline" else Color.WHITE

func set_has_message(value: bool) -> void:
	_has_message = value
	if _has_message:
		message_bubble.show()
		_start_bubble_blink()
	else:
		message_bubble.hide()
		if _bubble_tween:
			_bubble_tween.kill()
			_bubble_tween = null
		message_bubble.modulate = Color(1.0, 0.8, 0.0, 1.0)

func _start_bubble_blink() -> void:
	if _bubble_tween:
		_bubble_tween.kill()
	_bubble_tween = create_tween().set_loops()
	_bubble_tween.tween_property(message_bubble, "modulate", Color(1.0, 0.8, 0.0, 0.2), 0.5)
	_bubble_tween.tween_property(message_bubble, "modulate", Color(1.0, 0.8, 0.0, 1.0), 0.5)

func _on_user_updated(uid: int, _fields: Array) -> void:
	if uid != _friend_id: return
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_has_message(false)
		clicked.emit(_friend_id)
		accept_event()

func _on_pressed() -> void:
	set_has_message(false)
	AudioController.play("Select-2")
	clicked.emit(_friend_id)

func _on_mouse_entered() -> void:
	AudioController.play("Move-1")
	hovered.emit(_friend_id, global_position)

func _on_mouse_exited() -> void:
	unhovered.emit()
