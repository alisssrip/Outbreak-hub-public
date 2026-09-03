extends Node
class_name MV_BaseModule
var ctx: MainViewComponentSystem;

@export var window_panel : Panel
@export var scroll: SmoothScroll

func initState(hndlr : MainViewComponentSystem) -> MV_BaseModule:
	ctx = hndlr;
	return self;

func startState() -> void:
	return;

func updateState() -> void:
	return;

func exitState() -> void:
	return;

func _open_window() -> void:
	window_panel.show()
	if scroll != null:
		scroll.resetScroll()
		scroll.resetScroll.call_deferred()

func _close_window() -> void:
	window_panel.hide()
