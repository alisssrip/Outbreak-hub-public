@tool
class_name UserProfileUIBgSystem
extends Panel

@export_group("General")
@export var active_status : int = 0
@export var speed_part1: float = 1.0
@export var speed_part2: float = 1.0
@export var wait_part1: float = 0.5
@export var wait_part2: float = 0.5

@export_group("References")
@export var pulse_tex : TextureRect

@export_group("Pulse value")
@export var pulse_speed : float = 1
@export var pulse_wait_to_exit : float = 1.0
@export var pulse_wait_to_enter : float = 1.0
@export var pulse_paused : bool = true
@export_range(0.0, 2.0) var scroll_global : float = 1.0

@export var shader_material : Material
@export var status_store : Array[Status_variant]

var _mat : Material

func _ready():
	_mat = shader_material.duplicate()
	pulse_tex.material = _mat
	_set_shader(_mat)
	_pulse_anim();
	return


func _change_active_status(status : int) -> void:
	active_status = status
	_set_shader(_mat)
	return

func _set_shader(mat: Material) -> void:
	# colors and stuff
	var config : Status_Shader_Config = status_store[active_status].status_shader_config

	
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

	pulse_paused = !config.pulse_anim
	return


var pulse_anim_value := 0.0

func _pulse_anim() -> void:
	while true:
		var tween = create_tween()
		tween.tween_property(self, "pulse_anim_value", 1.1, speed_part1)
		await tween.finished
		await get_tree().create_timer(wait_part1).timeout
		tween = create_tween()
		tween.tween_property(self, "pulse_anim_value", 2, speed_part2)
		await tween.finished
		await get_tree().create_timer(wait_part2).timeout
		pulse_anim_value = 0
func _process(delta):
	if !pulse_paused:
		scroll_global = pulse_anim_value
		_mat.set_shader_parameter("scroll_global", scroll_global)

	return
