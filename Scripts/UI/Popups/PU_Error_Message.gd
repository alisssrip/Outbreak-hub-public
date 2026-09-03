class_name PU_Error_Message
extends BasePopup

@export var title : Label
@export var message : RichTextLabel
@export var accept_btn : Button

func _setup_popup() -> void:
	if accept_btn:
		accept_btn.pressed.connect(_on_accept_pressed)

func setup_error(error_title: String, error_msg: String) -> void:
	if title: title.text = error_title
	if message:
		message.text = error_msg
		fit_width_to_text(message, error_msg)

func _on_accept_pressed() -> void:
	close_popup()
func focus_element() -> void:
	accept_btn.grab_focus()
	pass