class_name UIMainviewHeaderButtonSystem
extends HBoxContainer

signal button_pressed(index: int)

@export var buttons : Array[Button]
@export var group : ButtonGroup

@export_group("Animation Notification")
@export var notification_color: Color = Color(1.6, 1.2, 0.5)
@export var pulse_duration: float = 0.8

@export_group("Selection")
@export var allow_unpress: bool = false
@export var initial_selected: int = -1

@export_group("Debug")
@export var debug_notification_enabled: bool = false:
	set(value):
		debug_notification_enabled = value
		if is_node_ready():
			_apply_debug_notification()
@export var debug_notification_index: int = 0:
	set(value):
		debug_notification_index = value
		if is_node_ready():
			_apply_debug_notification()

const FONT_COLOR := "theme_override_colors/font_color"
const FONT_HOVER_COLOR := "theme_override_colors/font_hover_color"
const ICON_COLOR := "theme_override_colors/icon_normal_color"
const ICON_HOVER_COLOR := "theme_override_colors/icon_hover_color"

var _button_group: ButtonGroup
var _notification_tweens: Dictionary = {}
var _original_font_colors: Dictionary = {}
var _original_font_hover_colors: Dictionary = {}
var _original_icon_colors: Dictionary = {}
var _original_icon_hover_colors: Dictionary = {}


func _ready() -> void:
	_button_group = ButtonGroup.new()
	_button_group.allow_unpress = allow_unpress
	
	for child in buttons:
		var button = child
		if button == null:
			continue
		button.toggle_mode = true
		button.button_group = _button_group
		button.pressed.connect(_on_button_pressed.bind(button))
		# Cacheamos el color "normal" como base. Para hover usamos el mismo
		# para que el efecto se mantenga estable con o sin mouse encima.
		var font_normal: Color = button.get_theme_color("font_color")
		var icon_normal: Color = button.get_theme_color("icon_normal_color")
		_original_font_colors[button] = font_normal
		_original_font_hover_colors[button] = font_normal
		_original_icon_colors[button] = icon_normal
		_original_icon_hover_colors[button] = icon_normal
	LauncherController.instance.emulator_opened.connect(_on_game_launched)
	LauncherController.instance.emulator_closed.connect(_on_game_closed)
	
	if initial_selected >= 0 and initial_selected < buttons.size():
		buttons[initial_selected].button_pressed = true
	
	_apply_debug_notification()


func set_button_enabled(index: int, enabled: bool) -> void:
	if not _is_valid_index(index):
		return
	buttons[index].disabled = not enabled


func set_button_visible(index: int, is_visible: bool) -> void:
	if not _is_valid_index(index):
		return
	buttons[index].visible = is_visible


func set_notification(index: int, active: bool) -> void:
	if not _is_valid_index(index):
		return
	var button := buttons[index]
	_kill_notification_tween(button)
	
	var font_normal: Color = _original_font_colors[button]
	var font_hover: Color = _original_font_hover_colors[button]
	var icon_normal: Color = _original_icon_colors[button]
	var icon_hover: Color = _original_icon_hover_colors[button]
	
	if active:
		var tween := create_tween().set_loops().set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(button, FONT_COLOR, notification_color, pulse_duration)
		tween.tween_property(button, FONT_HOVER_COLOR, notification_color, pulse_duration)
		tween.tween_property(button, ICON_COLOR, notification_color, pulse_duration)
		tween.tween_property(button, ICON_HOVER_COLOR, notification_color, pulse_duration)
		tween.chain().tween_property(button, FONT_COLOR, font_normal, pulse_duration)
		tween.parallel().tween_property(button, FONT_HOVER_COLOR, font_hover, pulse_duration)
		tween.parallel().tween_property(button, ICON_COLOR, icon_normal, pulse_duration)
		tween.parallel().tween_property(button, ICON_HOVER_COLOR, icon_hover, pulse_duration)
		_notification_tweens[button] = tween
	else:
		button.add_theme_color_override("font_color", font_normal)
		button.add_theme_color_override("font_hover_color", font_hover)
		button.add_theme_color_override("icon_normal_color", icon_normal)
		button.add_theme_color_override("icon_hover_color", icon_hover)


func _on_button_pressed(button: BaseButton) -> void:
	var index := buttons.find(button)
	if _notification_tweens.has(button):
		set_notification(index, false)
	button_pressed.emit(index)

func _press_btn(btn: String, ignorePressed : bool = false) -> void:
	var btnReference: Button = null
	match btn:
		"News":
			btnReference = buttons[0]
		"Profile":
			btnReference = buttons[1]
		"Chat":
			btnReference = buttons[2]
		"Configuration":
			btnReference = buttons[3]
		"Server":
			btnReference = buttons[4]
	if(btnReference == null): btnReference = buttons[0]
	if btnReference.button_pressed == true and !ignorePressed: return
	btnReference.button_pressed = true;
	_on_button_pressed(btnReference)
	return



func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < buttons.size()


func _kill_notification_tween(button: BaseButton) -> void:
	if _notification_tweens.has(button):
		var tween: Tween = _notification_tweens[button]
		if tween and tween.is_valid():
			tween.kill()
		_notification_tweens.erase(button)


func _apply_debug_notification() -> void:
	if not _is_valid_index(debug_notification_index):
		return
	set_notification(debug_notification_index, debug_notification_enabled)

func _on_game_launched() -> void:
	buttons[4].disabled = true
	buttons[4].mouse_default_cursor_shape = Control.CURSOR_ARROW
	buttons[3].disabled = true
	buttons[3].mouse_default_cursor_shape = Control.CURSOR_ARROW
	return
func _on_game_closed() -> void:
	buttons[4].disabled = false
	buttons[4].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buttons[3].disabled = false
	buttons[3].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND