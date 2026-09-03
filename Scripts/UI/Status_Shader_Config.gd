class_name Status_Shader_Config
extends Resource


@export_group("Shader main configs")
@export var text_color : Color = Color(0.133, 0.655, 0.192)
@export var border_color : Color = Color(0.133, 0.655, 0.192)
@export var pulse_anim : bool = true;
@export_subgroup("Pulse Texture")
@export var pulse_texture : Texture2D
@export_subgroup("Mask colors")
@export var background_color : Color = Color(0.0, 0.0, 0.0)
@export var lines_color : Color = Color(0.0, 0.769, 0.243)
@export var pulse_color : Color = Color(0.0, 0.741, 0.239)
@export var arrowhead_color: Color = Color(0.0, 4.614, 3.443)
@export var two_lines_color : Color = Color(0.0, 1.495, 0.516)

@export_subgroup("Glow values")
@export var glow_blur : float = 4.801
@export var glow_strength : float = 1.523
@export var glow_flicker_speed : float = 3.273
@export var glow_fliker_amount : float = 0.377

@export_subgroup("Fog values")
@export var fog_speed : float = 0.096
@export var fog_scale : float = 1.139
@export var fog_color : Color = Color.WHITE
