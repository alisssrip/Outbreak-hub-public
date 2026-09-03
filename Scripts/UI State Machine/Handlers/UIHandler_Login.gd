extends UI_Hanlder
class_name UI_Hanlder_Login

@export var loginControl: Control;
@export var userLoginField: LineEdit;
@export var pswrdLoginField: LineEdit;
@export var sndLoginBtn: Button;
@export var restorePasswordContainer: Control;
@export var restorePasswordBtn: Button;
@export var createAccountBtn: Button;
@export var errormsg: Label;

signal on_login_pressed;
signal on_Restore_Pass_Pressed;
signal on_Create_Account_Pressed;

func _ready() -> void:
		sndLoginBtn.pressed.connect(_on_submited_button)
		restorePasswordBtn.pressed.connect(func(): on_Restore_Pass_Pressed.emit())
		createAccountBtn.pressed.connect(func(): on_Create_Account_Pressed.emit())
		userLoginField.text_submitted.connect(_on_submited)
		pswrdLoginField.text_submitted.connect(_on_submited)
		userLoginField.grab_focus()

		return;
func set_error_nsg(text: String) -> void:
	pswrdLoginField.grab_focus()
	pswrdLoginField.text = ""
	errormsg.text = text;
	return;
func _show_all() -> void:
	loginControl.show();
	return;
	
func _hide_all() -> void:
	loginControl.hide();
	return;

func _on_submited(text: String) -> void:
	on_login_pressed.emit()
	return
func _on_submited_button() -> void:
	on_login_pressed.emit()
	return

func _fade_all(fadeIn : bool, time : float, oncomplete: Callable) -> void:
	var tween := create_tween()
	var target_opacity := 1.0 if fadeIn else 0.0
	tween.tween_property(loginControl, "modulate:a", target_opacity, time)
	if oncomplete.is_valid():
		tween.finished.connect(oncomplete)
	return;

func _fade_element(element: String, fadeIn: bool, time: float, oncomplete: Callable) -> void:
	var tween := create_tween()
	var target_opacity := 1.0 if fadeIn else 0.0
	tween.tween_property(_findObject(element), "modulate:a", target_opacity, time)
	return;

func _findObject(element: String) -> Control:
	var node = find_child(element, true, false)
	return node if node is Control else null
