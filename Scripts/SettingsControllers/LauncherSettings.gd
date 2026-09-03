extends Resource
class_name LauncherSettings

@export var resolution = 1
@export var game_path := ""
@export var bios_path := ""

@export var full_screen := 0
@export var dynamic_graphics := 0
@export var graphics_preset := 0
@export var aspect_ratio := 1
@export var fmv_override := 0
@export var deinterlace := 0
@export var texture_filter := 2
@export var bilinear := 1
@export var trilinear := 0
@export var anisotropic := 0
@export var dithering := 2
@export var internal_res := 0
@export var enable_ra := 0
@export var enable_hard_mode := 0
@export var ra_nickname := ""
@export var ra_token : String = ""

@export var advanced_enabled := 0

@export var selected_server := 0

@export var guide_shown := 0

@export var discord_presence := 1

@export var bindings := {}

func to_dict() -> Dictionary:
	return {
		"resolution": resolution,
		"game_path": game_path,
		"bios_path": bios_path,
		"full_screen": full_screen,
		"dynamic_graphics": dynamic_graphics,
		"graphics_preset": graphics_preset,
		"aspect_ratio": aspect_ratio,
		"fmv_override": fmv_override,
		"deinterlace": deinterlace,
		"texture_filter": texture_filter,
		"bilinear": bilinear,
		"trilinear": trilinear,
		"anisotropic": anisotropic,
		"dithering": dithering,
		"internal_res": internal_res,
		"enable_ra": enable_ra,
		"enable_hard_mode": enable_hard_mode,
		"ra_nickname": ra_nickname,
		"ra_token": ra_token,
		"advanced_enabled": advanced_enabled,
		"selected_server": selected_server,
		"guide_shown": guide_shown,
		"discord_presence": discord_presence,
		"bindings": bindings,
	}

func from_dict(data: Dictionary) -> void:
	for key in data:
		if not (key in self):
			continue
		var current = get(key)
		var value = data[key]
		if current is int and value is float:
			value = int(value)
		set(key, value)

func is_advanced_enabled() -> bool:
	return advanced_enabled == 1