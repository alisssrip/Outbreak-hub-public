extends SettingRow
class_name JoypadPresetRow

@export var option: OptionButton
@export var button: Button
@export var bindings_root: Node

var _order: Array[int] = []
var _currentIndex: int = 0

func _ready() -> void:
	super()
	button.pressed.connect(_on_apply_pressed)
	LauncherController.instance.on_joystick_connected.connect(_on_joy_connection_changed)
	_rebuild_list()

func _on_joy_connection_changed(connected: bool, device: int) -> void:
	if connected:
		if not _order.has(device):
			_order.append(device)
			_rebuild_list()
	else:
		_order.erase(device)
		_refresh_options()
		var size = _order.size()
		if _currentIndex > size - 1:
			_change_value(0)


func _rebuild_list() -> void:
	_order.clear()
	for device in Input.get_connected_joypads():
		_order.append(device)
	_refresh_options()

func _refresh_options() -> void:
	var previous := option.selected
	option.clear()
	if _order.is_empty():
		option.add_item(tr("PAD_NO_CONTROLLERS"))
		option.disabled = true
		button.disabled = true
		return
	option.disabled = false
	button.disabled = false
	for i in _order.size():
		option.add_item("SDL-%d  %s" % [i, Input.get_joy_name(_order[i])])
	if previous >= 0 and previous < option.item_count:
		option.select(previous)
	else:
		option.select(0)

func _on_apply_pressed() -> void:
	var idx := option.selected
	_currentIndex = idx
	if idx < 0 or idx >= _order.size():
		return
	for row in _collect_bindings():
		var input := str(row.get("default_joy_input"))
		if input.is_empty():
			continue
		row.apply_binding("SDL-%d/%s" % [idx, input])

func _change_value(value: int) -> void:
	_currentIndex = value
	option.selected = _currentIndex
	_on_apply_pressed()
	return

func _collect_bindings() -> Array:
	if bindings_root == null:
		return []
	return bindings_root.find_children("*", "BindingRow", true, false)

func set_value(value: Variant) -> void:
	var target := str(value)
	if target.is_empty():
		return
	for i in _order.size():
		if Input.get_joy_name(_order[i]) == target:
			option.select(i)
			return

func get_value() -> Variant:
	var idx := option.selected
	if idx < 0 or idx >= _order.size():
		return ""
	return Input.get_joy_name(_order[idx])
