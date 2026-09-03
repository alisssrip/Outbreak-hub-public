class_name DragWindow
extends Control

@export var version : Label;

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		DisplayServer.window_start_drag()

func _set_version(ver : String) -> void:
	version.text = tr("APP_VERSION_LABEL") % ver
	return
