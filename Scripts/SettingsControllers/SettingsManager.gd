extends Node

const SAVE_PATH := "user://settings.json"

var settings: LauncherSettings

func _ready() -> void:
	settings = load_settings()

func save_settings() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		Log.d("save fail: ", FileAccess.get_open_error(), " dir: ", OS.get_user_data_dir())
		return
	f.store_string(JSON.stringify(settings.to_dict()))
	f.close()
	Log.d("save ok: ", OS.get_user_data_dir())

func load_settings() -> LauncherSettings:
	var s := LauncherSettings.new()
	if not FileAccess.file_exists(SAVE_PATH):
		Log.d("no settings file: ", OS.get_user_data_dir())
		return s
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		Log.d("load fail: ", FileAccess.get_open_error())
		return s
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		s.from_dict(data)
	else:
		Log.d("load parse fail")
	return s