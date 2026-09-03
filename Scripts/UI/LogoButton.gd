extends Node

@export var mainView : MainViewComponentSystem
@export var logo : TextureRect

@export_group("Logo Brightness")
@export var base_color : Color = Color(1.0, 1.0, 1.0)
@export var value_idle : float = 0.5
@export var value_hover : float = 1.0
@export var value_pressed : float = 0.0

@export_group("Logo Animation")
@export var transition_time : float = 0.15
@export var pulse_time : float = 0.7
@export var pulse_amount : float = 0.2

var _hovering : bool = false
var _pulse_tween : Tween

func _ready() -> void:
	logo.modulate = _color_with_value(value_idle)
	logo.mouse_filter = Control.MOUSE_FILTER_STOP
	logo.mouse_entered.connect(_on_logo_entered)
	logo.mouse_exited.connect(_on_logo_exited)
	logo.gui_input.connect(_on_logo_gui_input)

func _on_logo_entered() -> void:
	_hovering = true
	_fade_to_hover_then_pulse()

func _on_logo_exited() -> void:
	_hovering = false
	_stop_pulse()
	_fade_to_value(value_idle)

func _on_logo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_stop_pulse()
			_fade_to_value(value_pressed, transition_time * 0.5)
		else:
			_to_news()
			if _hovering:
				_fade_to_hover_then_pulse()
			else:
				_fade_to_value(value_idle)

func _color_with_value(v: float) -> Color:
	var c := base_color
	c.v = v
	return c

func _fade_to_value(v: float, time: float = -1.0) -> void:
	var t := transition_time if time < 0.0 else time
	var tween := create_tween()
	tween.tween_property(logo, "modulate", _color_with_value(v), t)

func _fade_to_hover_then_pulse() -> void:
	_stop_pulse()
	var tween := create_tween()
	tween.tween_property(logo, "modulate", _color_with_value(value_hover), transition_time)
	tween.finished.connect(_start_pulse, CONNECT_ONE_SHOT)

func _start_pulse() -> void:
	if not _hovering:
		return
	_stop_pulse()
	var bright := _color_with_value(value_hover)
	var dim := _color_with_value(value_hover - pulse_amount)
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(logo, "modulate", dim, pulse_time)
	_pulse_tween.tween_property(logo, "modulate", bright, pulse_time)

func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null

func _to_news() -> void:
	mainView.header._press_btn("News", true)