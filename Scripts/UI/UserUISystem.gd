@tool
class_name UserUISystem
extends Panel

signal _on_mini_profile_pressed

@export_group("General")
@export var active_status : int = 0
@export var speed_part1: float = 1.0
@export var speed_part2: float = 1.0
@export var wait_part1: float = 0.5
@export var wait_part2: float = 0.5
@export var border: NinePatchRect
@export var set_state : bool

@export_group("Pulse value")
@export var pulse_speed : float = 1
@export var pulse_wait_to_exit : float = 1.0
@export var pulse_wait_to_enter : float = 1.0
@export var pulse_paused : bool = true
@export_range(0.0, 2.0) var scroll_global : float = 1.0

@export_group("References")
@export var text_name : Label
@export var text_name_blur : Label
@export var text_status : Label
@export var text_status_blur : Label
@export var text_status_in_game : Label
@export var text_status_in_game_blur : Label
@export var text_infection : Label
@export var text_infection_blur : Label
@export var in_game_status_shadow : TextureRect
@export var infection_shadow : TextureRect
@export var pulse_tex : TextureRect
@export var avatar : TextureRect
@export var character : TextureRect
@export var button : Button

@export var shader_material : Material
@export var status_store : Array[Status_variant]

var _mat : Material

func _ready():
	active_status = 4;
	_mat = shader_material.duplicate()
	pulse_tex.material = _mat
	_set_shader(_mat)
	if button != null :
		button.pressed.connect(mini_profile_pressed)
	return


func _set_avatar(_avatar: Texture2D) -> void:
	if avatar != null and _avatar != null:
		avatar.texture = _avatar
	return

func _set_character(texture: Texture2D) -> void:
	pass

	#character.texture = texture

func _change_text_in_game_status_label(text: String) -> void:
	text_status_in_game.text = text
	text_status_in_game_blur.text = text
	if text == "":
		in_game_status_shadow.hide()
	else :
		in_game_status_shadow.show()
	return

func _change_color_in_game_status_label(color: Color) -> void:
	text_infection.add_theme_color_override("font_color", color)
	text_infection_blur.add_theme_color_override("font_color", color)
	return

func _change_text_infection_label(text: String) -> void:
	text_infection.text = text
	text_infection_blur.text = text
	if text == "":
		infection_shadow.hide()
	else :
		infection_shadow.show()
	return

func _change_color_infection_label(color: Color) -> void:
	text_status_in_game.add_theme_color_override("font_color", color)
	text_status_in_game_blur.add_theme_color_override("font_color", color)
	return
	
func _change_color_name_and_status_labels(color: Color) -> void:
	text_name.add_theme_color_override("font_color", color)
	text_status.add_theme_color_override("font_color", color)
	text_name_blur.material.set_shader_parameter("glow_color", color)
	text_status_blur.material.set_shader_parameter("glow_color", color)
	return

func _change_active_status(status : int) -> void:
	active_status = status
	return

func _set_shader(mat: Material) -> void:
	var config : Status_Shader_Config = status_store[active_status].status_shader_config
	
	_set_status(status_store[active_status].status_name)
	
	border.modulate = config.border_color
	
	_change_color_name_and_status_labels(config.text_color)
	_change_color_infection_label(config.text_color)
	_change_color_in_game_status_label(config.text_color)
	
	mat.set_shader_parameter("backgroud_color", config.background_color)
	mat.set_shader_parameter("lines_color", config.lines_color)
	mat.set_shader_parameter("color_a", config.pulse_color)
	mat.set_shader_parameter("color_b", config.arrowhead_color)
	mat.set_shader_parameter("pulse_mask", config.pulse_texture)
	mat.set_shader_parameter("two_lines_color", config.two_lines_color)
	
	# glow
	mat.set_shader_parameter("glow_blur", config.glow_blur)
	mat.set_shader_parameter("glow_strength", config.glow_strength)
	mat.set_shader_parameter("glow_flicker_speed", config.glow_flicker_speed)
	mat.set_shader_parameter("glow_flicker_amount", config.glow_fliker_amount)
	
	#fog
	mat.set_shader_parameter("fog_color", config.fog_color)
	mat.set_shader_parameter("fog_speed", config.fog_speed)
	mat.set_shader_parameter("fog_scale", config.fog_scale)
	_pulse_anim()
	return

func _set_name(name: String) -> void:
	text_name.text = name
	text_name_blur.text = name
	return
func _set_status(status: String) -> void:
	text_status.text = status
	text_status_blur.text = status
	return

func _process(delta):
	_update_pulse(delta)
	if !pulse_paused:
		scroll_global = pulse_anim_value
		_mat.set_shader_parameter("scroll_global", scroll_global)
	if set_state:
		_set_shader(_mat)
		set_state = false

	return

var pulse_anim_value := 0.0
var _pulse_phase := 0
var _pulse_time := 0.0
var _pulse_status := -1

func _pulse_anim() -> void:
	if _pulse_status == active_status:
		return
	_pulse_status = active_status
	_pulse_phase = 0
	_pulse_time = 0.0
	pulse_anim_value = 0.0
	return

func _pulse_phase_duration() -> float:
	match _pulse_phase:
		0: return speed_part1
		1: return wait_part1
		2: return speed_part2
		_: return wait_part2

func _update_pulse(delta: float) -> void:
	if active_status >= status_store.size():
		return
	if !status_store[active_status].status_shader_config.pulse_anim:
		return

	_pulse_time += delta
	var steps := 0
	while _pulse_time >= _pulse_phase_duration() and steps < 4:
		_pulse_time -= _pulse_phase_duration()
		_pulse_phase = (_pulse_phase + 1) % 4
		steps += 1

	var duration := _pulse_phase_duration()
	var t : float = clampf(_pulse_time / duration, 0.0, 1.0) if duration > 0.0 else 1.0
	match _pulse_phase:
		0: pulse_anim_value = t
		1: pulse_anim_value = 1.0
		2: pulse_anim_value = 1.0 + t
		_: pulse_anim_value = 2.0
	return

func mini_profile_pressed() -> void:
	_on_mini_profile_pressed.emit()
	return
