extends SettingRow
class_name DropdownRow

@export var option: OptionButton

func _ready() -> void:
	super()
	option.item_selected.connect(_on_item_selected)

func _on_item_selected(index: int) -> void:
	value_changed.emit(setting_key, get_value())

func set_value(value: Variant) -> void:
	for i in option.item_count:
		if option.get_item_id(i) == value:
			option.select(i)
			return
	_select_default()

func get_value() -> Variant:
	return option.get_item_id(option.selected)

func _select_default() -> void:
	for i in option.item_count:
		if option.get_item_id(i) == default_value:
			option.select(i)
			return
	if option.item_count > 0:
		option.select(0)