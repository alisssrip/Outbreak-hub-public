class_name PCSX2_Achievements
extends RefCounted

const VERIFY_CACHE_SECONDS := 120

var ctx
var is_linked : bool = false

var _last_verify : int = 0

func init(hndlr) -> void:
	ctx = hndlr

func has_local_credentials() -> bool:
	var s := SettingsManager.settings
	return s.ra_nickname != "" and s.ra_token != ""

func emulator_has_token() -> bool:
	if not has_local_credentials():
		return false
	var path : String = ctx.ini.get_path("secrets.ini")
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var content := f.get_as_text()
	f.close()
	return SettingsManager.settings.ra_token in content

func repair_if_needed() -> bool: 
	if not has_local_credentials():
		return true
	if emulator_has_token() and emulator_ra_active():
		return true 
	Log.d("[ra] emulator config incomplete, reapplying") 
	return reapply_credentials()

func emulator_ra_active() -> bool: 
	var path : String = ctx.ini.get_path("PCSX2.ini") 
	if not FileAccess.file_exists(path): 
		return false 
	var f := FileAccess.open(path, FileAccess.READ) 
	if f == null: 
		return false 
	var content := f.get_as_text() 
	f.close() 
	if not "[Achievements]" in content: 
		return false 
	var username : String = SettingsManager.settings.ra_nickname 
	var has_enabled := "Enabled = true" in content or "Enabled=true" in content 
	var has_user := ("Username = %s" % username) in content or ("Username=%s" % username) in content 
	return has_enabled and has_user

func verify(on_done: Callable = func(_ok): pass, force: bool = false) -> void:
	if not has_local_credentials():
		is_linked = false
		on_done.call(false)
		return
	var now := int(Time.get_unix_time_from_system())
	if not force and is_linked and (now - _last_verify) < VERIFY_CACHE_SECONDS:
		repair_if_needed()
		on_done.call(true)
		return
	var s := SettingsManager.settings
	NetworkHandler.ra.verify_token(s.ra_nickname, s.ra_token, func(ok):
		is_linked = ok
		_last_verify = int(Time.get_unix_time_from_system())
		if ok:
			reapply_credentials()
		on_done.call(ok)
	)

func reapply_credentials() -> bool:
	if not has_local_credentials():
		return false
	var s := SettingsManager.settings
	if not set_credentials(s.ra_nickname, s.ra_token):
		return false
	if not set_enabled(true):
		return false
	return set_hardcore(s.enable_hard_mode == 1)

func disconnect_account() -> void:
	is_linked = false
	_last_verify = 0
	_clear_credentials()
	var s := SettingsManager.settings
	s.ra_nickname = ""
	s.ra_token = ""
	s.enable_ra = 0
	s.enable_hard_mode = 0
	SettingsManager.save_settings()

func set_enabled(enabled: bool) -> bool:
	return _write_flag("Enabled", enabled)

func set_hardcore(enabled: bool) -> bool:
	return _write_flag("Hardcore", enabled)

func set_credentials(ra_username: String, ra_token: String) -> bool:
	if not _write_main(ra_username):
		return false
	if not _write_secrets(ra_token):
		return false
	return true

func _clear_credentials() -> void:
	_write_flag("Enabled", false)
	_write_flag("Hardcore", false)
	_write_main("")
	_write_secrets("")

func _write_flag(key: String, value: bool) -> bool:
	var content = ctx.ini.read("PCSX2.ini")
	if content.is_empty(): return false
	var str_value := "true" if value else "false"
	if "[Achievements]" in content:
		content = ctx.ini.set_value_in_section(content, "Achievements", key, str_value)
	else:
		content += "\n[Achievements]\n%s = %s\n" % [key, str_value]
	return ctx.ini.write("PCSX2.ini", content)

func _write_main(ra_username: String) -> bool:
	var content = ctx.ini.read("PCSX2.ini")
	if content.is_empty(): return false
	var timestamp := str(int(Time.get_unix_time_from_system()))
	if "Username" in content:
		content = ctx.ini.set_value(content, "Username", ra_username)
		content = ctx.ini.set_value(content, "LoginTimestamp", timestamp)
	else:
		content = ctx.ini.insert_after_section(content, "Achievements", "Username", ra_username)
		content = ctx.ini.insert_after_section(content, "Achievements", "LoginTimestamp", timestamp)
	return ctx.ini.write("PCSX2.ini", content)

func _write_secrets(ra_token: String) -> bool:
	var path : String = ctx.ini.get_path("secrets.ini")
	var content := ""
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			content = f.get_as_text()
			f.close()
	if "[Achievements]" in content:
		if "Token" in content:
			content = ctx.ini.set_value(content, "Token", ra_token)
		else:
			content = ctx.ini.insert_after_section(content, "Achievements", "Token", ra_token)
	else:
		content += "\n[Achievements]\nToken = %s\n" % ra_token
	return ctx.ini.write("secrets.ini", content)