extends Base_State;
class_name Main_State;

@export var main_view : MainViewComponentSystem
@export var main_container: Control


func initState( hndlr : State_Controller) -> Base_State:
	ctx = hndlr;
	return self;

func startState() -> void:
	main_container.show()
	main_view._init_main_view()
	return;

func updateState() -> void:
	return;

func exitState() -> void:
	main_container.hide()
	return;

