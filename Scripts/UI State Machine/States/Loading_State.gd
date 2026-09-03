extends Base_State;
class_name Loading_State;

@export var loading : UI_Hanlder_Loading

func initState( hndlr : State_Controller) -> Base_State:
	ctx = hndlr;
	return self;

func startState() -> void:
	loading._show_all()
	loading._fullLoadScreenLoginTransition();
	await NetworkHandler.sleep(7);
	ctx._change_state(ctx.mainState) 
	return;

func updateState() -> void:
	return;

func exitState() -> void:
	loading._fullLoadScreenTransition(false);
	return;


	
