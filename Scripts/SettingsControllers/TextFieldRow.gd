extends SettingRow
class_name TextFieldRow

@export var field: LineEdit
@export var browse_button: TextureButton
@export var file_mode := false
@export var file_type: String

func _ready() -> void:
	super()
	field.text_submitted.connect(_on_text_submitted)
	field.focus_exited.connect(_on_focus_exited)
	if browse_button:
		browse_button.pressed.connect(_on_browse_pressed)

func _on_text_submitted(_t: String) -> void:
	_emit()

func _on_focus_exited() -> void:
	_emit()

func _on_browse_pressed() -> void:
	var mode: DisplayServer.FileDialogMode = DisplayServer.FILE_DIALOG_MODE_OPEN_FILE if file_mode else DisplayServer.FILE_DIALOG_MODE_OPEN_DIR
	var filters := PackedStringArray(["*.%s" % file_type]) if file_mode else PackedStringArray()
	match file_type:
		"bin":
			_confirm_then_pick(tr("SETTINGS_BIOS_REQUIREMENT"), mode, filters, _check_bios)
		"iso":
			_confirm_then_pick(tr("SETTINGS_ROM_REQUIREMENT"), mode, filters, _check_iso)
		_:
			_pick(mode, filters, Callable())

func _confirm_then_pick(message: String, mode: DisplayServer.FileDialogMode, filters: PackedStringArray, validator: Callable) -> void:
	Popups_Controller.instance.show_confirm(message, func(): _pick(mode, filters, validator), false)

func _pick(mode: DisplayServer.FileDialogMode, filters: PackedStringArray, validator: Callable) -> void:
	var callback := func(status: bool, paths: PackedStringArray, _filter_index: int):
		if not status or paths.is_empty():
			return
		if validator.is_valid() and not validator.call(paths[0]):
			return
		_on_file_picked(paths[0])
	var error := open_dialog(mode, filters, callback)
	if error != OK:
		print("file dialog error ", error)

func _check_bios(path: String) -> bool:
	if Pcsx2Manager.is_bios_valid(path):
		return true
	Popups_Controller.instance.show_error(tr("SETTINGS_BIOS_INVALID_TITLE"), tr("SETTINGS_BIOS_INVALID_MSG"))
	return false

func _check_iso(path: String) -> bool:
	if Pcsx2Manager.is_valid_outbreak(path):
		return true
	Popups_Controller.instance.show_error(tr("SETTINGS_ROM_INVALID_TITLE"), tr("SETTINGS_ROM_INVALID_MSG"))
	return false

func open_dialog(mode: DisplayServer.FileDialogMode, filters: PackedStringArray, callback: Callable) -> int:
	return DisplayServer.file_dialog_show(
		tr("COMMON_SELECT_FILE") if file_mode else tr("COMMON_SELECT_FOLDER"),
		field.text if not field.text.is_empty() else "user://",
		"",
		false,
		mode,
		filters,
		callback
	)

func _on_file_picked(path: String) -> void:
	field.text = path
	_emit()

func _emit() -> void:
	value_changed.emit(setting_key, get_value())

func set_value(value: Variant) -> void:
	field.text = str(value)

func get_value() -> Variant:
	return field.text
