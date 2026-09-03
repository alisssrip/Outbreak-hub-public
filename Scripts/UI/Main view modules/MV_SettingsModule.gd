class_name MV_SettingsModule
extends MV_BaseModule

@export var configPanel : ConfigurationPanel

func initState(hndlr : MainViewComponentSystem) -> MV_BaseModule:
	ctx = hndlr;
	return self;

func startState() -> void:
	_open_window()

func updateState() -> void:
	return

func exitState() -> void:
	configPanel.close_panel()
	_close_window()

func _global_btn_pressed() -> void:

	return
