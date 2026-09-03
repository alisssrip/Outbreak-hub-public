class_name UserChatMessageSystem
extends Control

signal user_clicked(user_id: int)

@export var name_field : Label
@export var date_field : Label
@export var msg_field  : RichTextLabel
@export var image_icon : TextureRect

var user_name : String
var date : String
var msg : String
var user_id : int = 0

func _ready() -> void:
	name_field.gui_input.connect(_on_name_gui_input)
	name_field.mouse_filter = Control.MOUSE_FILTER_STOP
	name_field.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func setup_with_image(p_user: String, p_date: String, p_msg: String, p_image: Texture2D) -> void:
	user_name = p_user
	date = p_date
	msg = p_msg
	image_icon.texture = p_image
	image_icon.visible = true
	_update_fields()

func setup_without_image(p_user: String, p_date: String, p_msg: String) -> void:
	user_name = p_user
	date = p_date
	msg = p_msg
	if image_icon != null:
		image_icon.visible = false
	_update_fields()
		
func append_message(p_msg: String) -> void:
	msg += "\n" + p_msg
	msg_field.text = msg

func set_image(p_image: Texture2D) -> void:
	if image_icon == null: return
	image_icon.texture = p_image
	image_icon.visible = true

func set_user_id(uid: int) -> void:
	user_id = uid

func _update_fields() -> void:
	name_field.text = user_name
	date_field.text = date
	msg_field.text = msg

func _on_name_gui_input(event: InputEvent) -> void:
	if user_id <= 0: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		user_clicked.emit(user_id)