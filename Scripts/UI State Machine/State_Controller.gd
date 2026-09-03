extends Node
class_name State_Controller

var currentState: Base_State;

@export var loginState : Login_State
@export var loadingState : Loading_State
@export var mainState : Main_State

func _init_state_machine(initial: Base_State = null) -> void:
	loginState.initState(self)
	loadingState.initState(self)
	mainState.initState(self)
	_change_state(initial if initial != null else loginState)

func _change_state(state: Base_State) -> void:
	if currentState != null: currentState.exitState();
	currentState = state;
	currentState.startState();
	return;
