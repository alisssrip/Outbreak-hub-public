extends RefCounted
class_name Pcsx2Writer

const ASPECT := ["Stretch", "Auto 4:3/3:2", "4:3", "16:9", "10:7"]
const FMV := ["Off", "Auto 4:3/3:2", "4:3", "16:9", "10:7"]
const TRIFILTER := [-1, 0, 1, 2]
const ANISO := [0, 2, 4, 8, 16]

static func apply(ini_path: String, settings: LauncherSettings) -> bool:
	var f := FileAccess.open(ini_path, FileAccess.READ)
	if f == null:
		push_error("pcsx2 ini not found: " + ini_path)
		return false
	var text := f.get_as_text()
	f.close()

	var gs := {
		"AspectRatio": ASPECT[settings.aspect_ratio],
		"FMVAspectRatioSwitch": FMV[settings.fmv_override],
		"deinterlace_mode": settings.deinterlace,
		"linear_present_mode": settings.bilinear,
		"filter": settings.texture_filter,
		"TriFilter": TRIFILTER[settings.trilinear],
		"MaxAnisotropy": ANISO[settings.anisotropic],
		"dithering_ps2": settings.dithering,
		"accurate_blending_unit": settings.blending,
		"upscale_multiplier": settings.internal_res + 1,
	}

	var pad := {}
	for action in settings.bindings:
		pad[action] = settings.bindings[action]

	var sections := {
		"EmuCore/GS": gs,
		"Pad1": pad,
	}

	var out := _rewrite(text, sections)

	var wf := FileAccess.open(ini_path, FileAccess.WRITE)
	if wf == null:
		push_error("pcsx2 ini not writable: " + ini_path)
		return false
	wf.store_string(out)
	wf.close()
	return true

static func _rewrite(text: String, sections: Dictionary) -> String:
	var lines := text.split("\n")
	var result : PackedStringArray = []
	var current_section := ""
	var applied := {}

	for line in lines:
		var stripped := line.strip_edges()

		if stripped.begins_with("[") and stripped.ends_with("]"):
			_flush_missing(result, current_section, sections, applied)
			current_section = stripped.substr(1, stripped.length() - 2)
			result.append(line)
			continue

		if sections.has(current_section) and stripped.contains("="):
			var key := stripped.split("=")[0].strip_edges()
			var sec : Dictionary = sections[current_section]
			if sec.has(key):
				result.append("%s = %s" % [key, str(sec[key])])
				if not applied.has(current_section):
					applied[current_section] = {}
				applied[current_section][key] = true
				continue

		result.append(line)

	_flush_missing(result, current_section, sections, applied)
	return "\n".join(result)

static func _flush_missing(result: PackedStringArray, section: String, sections: Dictionary, applied: Dictionary) -> void:
	if not sections.has(section):
		return
	var sec : Dictionary = sections[section]
	var done : Dictionary = applied.get(section, {})
	for key in sec:
		if not done.has(key):
			result.append("%s = %s" % [key, str(sec[key])])
			if not applied.has(section):
				applied[section] = {}
			applied[section][key] = true

func _test_pcsx2_writer() -> void:
	var copia := OS.get_environment("HOME") + "/PCSX2_copia.ini"  # ajustá al path de tu copia

	var s := SettingsManager.settings
	s.aspect_ratio = 1
	s.fmv_override = 0
	s.deinterlace = 0
	s.bilinear = 1
	s.texture_filter = 2
	s.trilinear = 0
	s.anisotropic = 2
	s.dithering = 2
	s.blending = 1
	s.internal_res = 2 
	s.bindings = {
		"Cross": "Keyboard/K",
		"Circle": "Keyboard/L",
		"L2": "SDL-0/+LeftTrigger",
		"LUp": "SDL-0/-LeftY",
	}

	Pcsx2Writer.apply(copia, s)

	var f := FileAccess.open(copia, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	if OS.is_debug_build():
		Log.d(_extract_section(text, "[EmuCore/GS]"))
		Log.d("---")
		Log.d(_extract_section(text, "[Pad1]"))

func _extract_section(text: String, header: String) -> String:
	var lines := text.split("\n")
	var out := ""
	var capturing := false
	for line in lines:
		var stripped := line.strip_edges()
		if stripped == header:
			capturing = true
			out += line + "\n"
			continue
		if capturing and stripped.begins_with("[") and stripped.ends_with("]"):
			break
		if capturing:
			out += line + "\n"
	return out