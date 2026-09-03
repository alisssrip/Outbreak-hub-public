extends UI_Hanlder
class_name UI_Hanlder_Login_Loading

@export var lodingControl: Control;
@export var loadingBar: TextureRect;
@export var overImg: TextureRect;
@export var labelText: Label;
@export var barSpeed: float = 1;
@export var pointsTime: float = 1;

signal on_login_pressed;
signal on_Restore_Pass_Pressed;
signal on_Create_Account_Pressed;

var time: float;
var points := "."
func _process(delta: float) -> void:
	time += delta
	loadingBar.rotation += delta * barSpeed

	if time >= pointsTime:
		time = 0.0
		match points:
			".":
				points = ".."
			"..":
				points = "..."
			"..." , _:
				points = "."

	if labelText != null:
		labelText.text = tr("LOGIN_LOADING") + "\n" + points

func _hide_all() -> void:
	lodingControl.hide();
	return;
	
func _show_all() -> void:
	lodingControl.show();
	return;

func _fade_all(fadeIn : bool, time : float, oncomplete: Callable) -> void:
	var tween := create_tween()
	var target_opacity := 1.0 if fadeIn else 0.0
	tween.tween_property(lodingControl, "modulate:a", target_opacity, time)
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
