extends Node
class_name Base_State
var ctx: State_Controller;

func initState(hndlr : State_Controller) -> Base_State:
	ctx = hndlr;
	return self;

func startState() -> void:
	return;

func updateState() -> void:
	return;

func exitState() -> void:
	return;
