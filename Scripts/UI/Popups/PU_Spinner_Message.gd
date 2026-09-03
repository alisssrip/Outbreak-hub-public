class_name PU_Spinner_Message
extends BasePopup

@export var label : Label


func _setup_popup() -> void:
	return

func setup_spinner(message: String) -> void:
	if label: label.text = message

func open_popup() -> void:
	super.open_popup()

func close_popup() -> void:
	super.close_popup()

func set_text(message: String) -> void:
	if label: label.text = message
	label.grab_focus()
