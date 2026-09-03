extends HBoxContainer

@export var btn_exit: Button
@export var btn_minimize: Button

func _ready():
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_minimize.pressed.connect(_on_minimize_pressed)

func _on_exit_pressed():
	var shutdown = func():
		if ShutdownHandler != null:
			await ShutdownHandler._on_close()
		else:
			get_tree().quit()
	Popups_Controller.instance.show_confirm(tr("POPUP_EXIT_CONFIRM"), shutdown)

func _on_minimize_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
