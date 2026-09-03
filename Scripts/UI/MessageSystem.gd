class_name MessageSystem
extends Control

@export var msg_field : RichTextLabel
@export var togglable : Control
@export var tooltip_font : Font
@export var tooltip_font_size : int = 0

var user_name : String
var date : String
var msg : String
var user_id : int = 0

func _ready() -> void:
	if msg_field != null:
		msg_field.mouse_filter = Control.MOUSE_FILTER_PASS

func setup(p_user: String, p_date: String, p_msg: String) -> void:
	user_name = p_user
	date = p_date
	msg = p_msg
	_update_fields()

func set_user_id(uid: int) -> void:
	user_id = uid

func set_extra_visible(value: bool) -> void:
	if togglable != null:
		togglable.visible = value

func _update_fields() -> void:
	msg_field.text = msg
	tooltip_text = "%s | %s" % [user_name, date]

func _make_custom_tooltip(for_text: String) -> Object:
	var label := Label.new()
	label.text = for_text
	if tooltip_font != null:
		label.add_theme_font_override("font", tooltip_font)
	if tooltip_font_size > 0:
		label.add_theme_font_size_override("font_size", tooltip_font_size)
	return label