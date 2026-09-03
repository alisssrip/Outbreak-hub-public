class_name MV_Profile_RecordsSystem
extends Node

signal level_clicked(match_id: int, entry: Dictionary)

@export var record_prefab : PackedScene
@export var scroll : ScrollContainer
@export var records_container : VBoxContainer
@export var no_records : Label

var _open_character : MV_Profile_RecordsCharacter = null

func set_records(data: Array[MV_Profile_RecordData]) -> void:
	_open_character = null
	for child in records_container.get_children():
		child.queue_free()
	if data.size() == 0:
		no_records.show()
		scroll.hide()
		return
	no_records.hide()
	scroll.show()
	for item in data:
		var node : MV_Profile_RecordsCharacter = record_prefab.instantiate()
		records_container.add_child(node)
		node.setup(item)
		node.requested_open.connect(_on_character_open)
		node.level_clicked.connect(_on_level_clicked)

func _on_character_open(node: MV_Profile_RecordsCharacter) -> void:
	if _open_character != null and _open_character != node:
		_open_character.collapse()
	_open_character = node

func _on_level_clicked(match_id: int, entry: Dictionary) -> void:
	level_clicked.emit(match_id, entry)
