class_name PCSX2_AntiCheat
extends RefCounted

var ctx

const ADVANTAGE_HOTKEYS := [
	"SaveStateToSlot",
	"LoadStateFromSlot",
	"NextSaveStateSlot",
	"PreviousSaveStateSlot",
	"TogglePause",
	"ToggleSlowMotion",
	"ToggleTurbo",
	"HoldTurbo",
	"ToggleFrameLimit",
	"OpenPauseMenu",
]

const SPEEDHACKS := {
	"EECycleRate": "0",
	"EECycleSkip": "0",
}

const EMUCORE := {
	"EnableCheats": "false",
	"EnableWideScreenPatches": "false",
	"EnableNoInterlacingPatches": "false",
}

func init(hndlr) -> void:
	ctx = hndlr

func apply() -> bool:
	var content: String = ctx.ini.read("PCSX2.ini")
	if content.is_empty(): return false

	for key in SPEEDHACKS:
		content = ctx.ini.set_value_in_section(content, "EmuCore/Speedhacks", key, SPEEDHACKS[key])
	for key in EMUCORE:
		content = ctx.ini.set_value_in_section(content, "EmuCore", key, EMUCORE[key])
	for key in ADVANTAGE_HOTKEYS:
		content = ctx.ini.set_value_in_section(content, "Hotkeys", key, "")

	return ctx.ini.write("PCSX2.ini", content)