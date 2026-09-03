class_name MV_Profile_FavoriteCharacterSystem
extends Node

signal favorite_character_changed(character: String)

@export var portrait_rect : TextureRect
@export var dropdown      : OptionButton
@export var name_label    : Label
@export var characters    : CharacterStore

var _current_index : int = 0
var _editable : bool = true

func _ready() -> void:
	_populate_dropdown()
	dropdown.item_selected.connect(_on_item_selected)
	name_label.hide()
	characters = LauncherController.instance.character

func _populate_dropdown() -> void:
	dropdown.clear()
	for character in characters.store:
		dropdown.add_item(character.character_name)

func set_favorite(character_name: String) -> void:
	for i in characters.store.size():
		if characters.store[i].character_name == character_name:
			_current_index = i
			dropdown.select(i)
			name_label.text = character_name
			_update_portrait(i)
			return
	name_label.text = character_name

func get_favorite() -> String:
	if characters.store.is_empty(): return ""
	return characters.store[_current_index].character_name

func set_editable(editable: bool) -> void:
	_editable = editable
	dropdown.visible = editable
	name_label.visible = not editable

func _on_item_selected(index: int) -> void:
	_current_index = index
	_update_portrait(index)
	if index < characters.store.size() and characters.store[index] != null:
		favorite_character_changed.emit(characters.store[index])

func _update_portrait(index: int) -> void:
	if index < characters.store.size():
		portrait_rect.texture = characters.store[index].portrait