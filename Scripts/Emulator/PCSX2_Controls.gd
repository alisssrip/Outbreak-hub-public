class_name PCSX2_Controls
extends RefCounted

var ctx

func init(hndlr) -> void:
	ctx = hndlr

func apply(settings: LauncherSettings) -> bool:
	var content = ctx.ini.read("PCSX2.ini")
	if content.is_empty(): return false

	for action in settings.bindings:
		content = ctx.ini.set_value_in_section(content, "Pad1", action, settings.bindings[action])

	return ctx.ini.write("PCSX2.ini", content)