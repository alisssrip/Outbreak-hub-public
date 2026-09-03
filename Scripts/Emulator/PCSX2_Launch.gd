class_name PCSX2_Launch
extends RefCounted

var ctx
var _pid := -1

signal game_started()
signal game_closed()

func init(hndlr) -> void:
	ctx = hndlr

func launch_game(iso_path: String) -> bool:
	var exe = ctx.paths.get_executable_path()
	var bios := SettingsManager.settings.bios_path
	if not FileAccess.file_exists(exe):
		Popups_Controller.instance.show_error(tr("LAUNCH_ERROR_TITLE"), tr("POPUP_PCSX2_MISSING"))
		return false
	if not FileAccess.file_exists(iso_path):
		Popups_Controller.instance.show_error(tr("LAUNCH_ERROR_TITLE"), tr("LAUNCH_ISO_MISSING"), _offer_setup_guide)
		return false
	if not FileAccess.file_exists(bios):
		Popups_Controller.instance.show_error(tr("LAUNCH_ERROR_TITLE"), tr("LAUNCH_BIOS_MISSING"))
		return false
	if not Pcsx2Manager.ini._write_bios_to_ini(_native_path(bios)):
		return false
	var args := ["-portable", "-nogui", "-batch"]
	if SettingsManager.settings.full_screen == 1:
		args.append("-fullscreen")
	args.append("--")
	args.append(_native_path(iso_path))
	_pid = OS.create_process(_native_path(exe), args)
	if _pid == -1:
		push_error("failed to launch pcsx2")
		return false
	ctx.start_monitoring()
	return true

func _offer_setup_guide() -> void:
	Popups_Controller.instance.show_confirm(
		tr("LAUNCH_SETUP_GUIDE"),
		func(): OS.shell_open(LauncherController.setup_guide_url()))

func _native_path(path: String) -> String:
	if OS.get_name() == "Windows":
		return path.replace("/", "\\")
	return path

func kill() -> void:
	if _pid != -1 and OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1

func is_running() -> bool:
	if _pid != -1 and OS.is_process_running(_pid):
		return true
	return _any_instance_running()

func _any_instance_running() -> bool:
	var out := []
	if OS.get_name() == "Windows":
		var code := OS.execute("tasklist", ["/FI", "IMAGENAME eq pcsx2-qt.exe"], out, true)
		return code == 0 and "pcsx2-qt.exe" in str(out)
	return OS.execute("pgrep", ["-x", "pcsx2-qt"], out, true) == 0

func get_pid() -> int:
	return _pid