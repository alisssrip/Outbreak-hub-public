class_name MV_Profile_HistorySystem
extends Node

signal row_clicked(match_id: int, entry: Dictionary)

@export var row_prefab : PackedScene
@export var scroll : ScrollContainer
@export var rows_container : VBoxContainer
@export var no_history : Label

func set_history(data: Array) -> void:
	for child in rows_container.get_children():
		child.queue_free()
	if data.size() == 0:
		no_history.show()
		scroll.hide()
		return
	no_history.hide()
	scroll.show()
	for item in data:
		var row : MV_Profile_HistoryRow = row_prefab.instantiate()
		rows_container.add_child(row)
		row.set_data(item)
		row.clicked.connect(_on_row_clicked)

func _on_row_clicked(match_id: int, entry: Dictionary) -> void:
	row_clicked.emit(match_id, entry)
