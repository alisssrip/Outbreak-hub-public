extends Control
class_name ConfigurationPanel
@export var binding_rows: Array[BindingRow] = []
@export var setting_rows: Array[SettingRow] = []

func _ready() -> void:
	_populate_rows()
	_connect_rows()
	Log.d("bindings: ", binding_rows.size(), " settings: ", setting_rows.size())
	ResolutionController.on_resolution_changed.connect(_resolution_changed)

func _connect_rows() -> void:
	for row in setting_rows:
		row.value_changed.connect(_on_value_changed)
		if row is ActionRow:
			row.action_triggered.connect(_on_action_triggered)
	for row in binding_rows:
		row.value_changed.connect(_on_value_changed)

func _populate_rows() -> void:
	var s := SettingsManager.settings
	for row in setting_rows:
		if not (row is ActionRow):
			row.set_value(s.get(row.setting_key))
	for row in binding_rows:
		row.set_value(s.bindings.get(row.setting_key, ""))

func _on_value_changed(key: String, value: Variant) -> void:
	var s := SettingsManager.settings
	if _is_binding_key(key):
		s.bindings[key] = value
		Log.d("BIND saved: ", key, " = ", value, " dict: ", s.bindings)
	else:
		s.set(key, value)
		Log.d("SETTING saved: ", key, " = ", value)
		execute_on_change_action(key, value)
	SettingsManager.save_settings()

func execute_on_change_action(key: String, value: Variant) -> void:
	match key:
		"resolution":
			ResolutionController._set_specific_res(value)
		"graphics_preset":
			_apply_graphics_preset(value)
		_: return

func _apply_graphics_preset(index: int) -> void:
	var preset : Dictionary = Pcsx2Manager.graphics.get_preset(index)
	if preset.is_empty():
		Log.d("unknown graphics preset: ", index)
		return
	var s := SettingsManager.settings
	for key in preset:
		s.set(key, preset[key])
	for row in setting_rows:
		if preset.has(row.setting_key):
			row.set_value(preset[row.setting_key])
	Log.d("graphics preset applied: ", index)

func _resolution_changed(index: int) -> void:
	var resolution_index = 0
	for i in setting_rows.size():
		if setting_rows[i].setting_key == "resolution":
			resolution_index = i
	setting_rows[resolution_index].set_value(index)

func _is_binding_key(key: String) -> bool:
	for row in binding_rows:
		if row.setting_key == key:
			return true
	return false

func _on_action_triggered(key: String) -> void:
	match key:
		"connect_ra":
			_connect_retroachievements()
		"open_advanced":
			_open_advanced_settings()
		"open_emulator":
			_open_emulator()

func close_panel() -> void:
	SettingsManager.save_settings()
	hide()

func _connect_retroachievements() -> void:
	return

func _open_advanced_settings() -> void:
	var path = Pcsx2Manager.paths.get_ini_path("PCSX2.ini")
	OS.shell_open(path)

func _open_emulator() -> void:
	var exe := Pcsx2Manager.paths.get_executable_path()
	if not FileAccess.file_exists(exe):
		Popups_Controller.instance.show_error(tr("POPUP_EMULATOR_TITLE"), tr("POPUP_PCSX2_MISSING"))
		return
	if OS.get_name() == "Windows":
		exe = exe.replace("/", "\\")
	if OS.create_process(exe, ["-portable"]) == -1:
		Popups_Controller.instance.show_error(tr("POPUP_EMULATOR_TITLE"), tr("POPUP_PCSX2_START_FAILED"))
