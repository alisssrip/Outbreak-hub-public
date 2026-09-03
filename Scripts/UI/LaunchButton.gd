extends Node
class_name LaunchButton
@export var button: Button
@export var name_blur : Control
@export var name_label : Label

@export_group("Intensity")
@export var intensity_idle : float = 0.0
@export var intensity_hover : float = 1.0
@export var intensity_pressed : float = 0.6

@export_group("Mapped Values")
@export var blur_max : float = 1.3
@export var color_off : Color = Color(0.5, 0.5, 0.5)
@export var color_on : Color = Color(1.0, 1.0, 1.0)

@export_group("Animation")
@export var transition_time : float = 0.18
@export var press_time : float = 0.08

@export_group("Shader Params")
@export var bg_state_param : String = "State"
@export var blur_param : String = "Blur Amount"
@export var label_color_override : String = "font_color"

var game_launched : bool = false

var _hovering : bool = false
var _intensity : float = 0.0
var _tween : Tween
var disable_event_pressed : bool

func _ready() -> void:
	button.mouse_entered.connect(_on_entered)
	button.mouse_exited.connect(_on_exited)
	button.gui_input.connect(_on_gui_input)
	button.pressed.connect(_button_pressed)
	LauncherController.instance.emulator_opened.connect(_on_game_launched)
	LauncherController.instance.emulator_closed.connect(_on_game_closed)
	_apply_intensity(intensity_idle)

func _on_entered() -> void:
	if game_launched: return
	_hovering = true
	_animate_to(intensity_hover, transition_time)

func _on_exited() -> void:
	_hovering = false
	_animate_to(intensity_idle, transition_time)

func _on_gui_input(event: InputEvent) -> void:
	if game_launched: return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		_animate_to(intensity_pressed, press_time)
	else:
		_button_pressed()

func _animate_to(target: float, time: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_intensity, _intensity, target, time)

func _apply_intensity(value: float) -> void:
	_intensity = value
	name_blur.material.set_shader_parameter(blur_param, value * blur_max)
	name_label.add_theme_color_override(label_color_override, color_off.lerp(color_on, value))

func _button_pressed() -> void:
	if game_launched: return
	LauncherController.instance._launch_game()

func _on_game_launched() -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	button.disabled = true
	game_launched = true
	_on_exited()
	return
func _on_game_closed() -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.disabled = false
	game_launched = false
	disable_event_pressed = false
