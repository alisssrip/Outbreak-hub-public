class_name PCSX2_Paths
extends RefCounted

var ctx
var _base_dir := ""

const PCSX2_SUBDIR := "PCSX2/usr/bin/"
const INIS_SUBDIR := "inis"


func init(hndlr) -> void:
	ctx = hndlr
	_base_dir = _resolve_base_dir()

func get_ini_path(filename: String) -> String:
	return _base_dir.path_join(PCSX2_SUBDIR).path_join(INIS_SUBDIR).path_join(filename)

func get_executable_path() -> String:
	var exe := "pcsx2-qt.exe" if OS.get_name() == "Windows" else "pcsx2-qt"
	return _base_dir.path_join(PCSX2_SUBDIR).path_join(exe)

func get_pcsx2_dir() -> String:
	return _base_dir.path_join(PCSX2_SUBDIR)

func _resolve_base_dir() -> String:
	if OS.has_feature("editor"):
		var base := Endpoints.get_url("editor_base")
		if not base.is_empty():
			return base
		return ProjectSettings.globalize_path("res://")
	return OS.get_executable_path().get_base_dir()