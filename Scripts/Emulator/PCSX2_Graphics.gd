class_name PCSX2_Graphics
extends RefCounted

var ctx

const ASPECT := ["Stretch", "Auto 4:3/3:2", "4:3", "16:9", "10:7"]
const FMV := ["Off", "Auto 4:3/3:2", "4:3", "16:9", "10:7"]
const TRIFILTER := [-1, 0, 1, 2]
const ANISO := [0, 2, 4, 8, 16]

const PRESETS := [
	{"internal_res": 0, "texture_filter": 2, "trilinear": 0, "anisotropic": 0},
	{"internal_res": 1, "texture_filter": 2, "trilinear": 0, "anisotropic": 1},
	{"internal_res": 2, "texture_filter": 2, "trilinear": 0, "anisotropic": 2},
	{"internal_res": 5, "texture_filter": 2, "trilinear": 0, "anisotropic": 4},
]

func init(hndlr) -> void:
	ctx = hndlr

func get_preset(index: int) -> Dictionary:
	if index < 0 or index >= PRESETS.size():
		return {}
	return PRESETS[index]

func apply(settings: LauncherSettings) -> bool:
	var content = ctx.ini.read("PCSX2.ini")
	if content.is_empty(): return false

	var values := {
		"AspectRatio": ASPECT[settings.aspect_ratio],
		"FMVAspectRatioSwitch": FMV[settings.fmv_override],
		"deinterlace_mode": str(settings.deinterlace),
		"linear_present_mode": str(settings.bilinear),
		"filter": str(clampi(settings.texture_filter, 0, 3)),
		"TriFilter": str(TRIFILTER[settings.trilinear]),
		"MaxAnisotropy": str(ANISO[settings.anisotropic]),
		"dithering_ps2": str(settings.dithering),
		"upscale_multiplier": str(settings.internal_res + 1),
	}

	for key in values:
		content = ctx.ini.set_value_in_section(content, "EmuCore/GS", key, values[key])

	return ctx.ini.write("PCSX2.ini", content)