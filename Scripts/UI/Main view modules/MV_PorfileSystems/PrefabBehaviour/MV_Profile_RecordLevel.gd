class_name MV_Profile_RecordLevel
extends VBoxContainer

signal clicked(match_id: int, entry: Dictionary)

@export var scenario_id : int
@export var background : Panel
@export var enabled_style : StyleBox
@export var disabled_style : StyleBox
@export var difficulty_label : Label
@export var time_label : Label
@export var infection_label : Label
@export var points_label : Label
@export var date_label : Label
@export var rank_label : Label
@export var click_button : Button

var _match_id : int = -1
var _entry : Dictionary = {}
var _empty : bool = true

func _ready() -> void:
	if click_button:
		click_button.pressed.connect(_on_pressed)
func set_interactable(enabled: bool) -> void:
	if click_button == null:
		return
	if _empty:
		click_button.disabled = true
		return
	click_button.disabled = not enabled

func set_data(data: MV_Profile_RecordLevelData) -> void:
	_empty = false
	_match_id = data.match_id
	_entry = data.raw
	difficulty_label.text = data.difficulty
	time_label.text = tr("RECORD_TIME") % data.time
	infection_label.text = tr("RECORD_INFECTION") % data.infection
	points_label.text = tr("RECORD_POINTS") % data.points
	date_label.text = data.date
	rank_label.text = tr("RECORD_RANK") % data.rank
	if background and enabled_style:
		background.add_theme_stylebox_override("panel", enabled_style)
	if click_button:
		click_button.disabled = false
		click_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_empty() -> void:
	_empty = true
	_match_id = -1
	_entry = {}
	difficulty_label.text = "---"
	time_label.text = "---"
	infection_label.text = "---"
	points_label.text = "---"
	date_label.text = "---"
	rank_label.text = "---"
	if background and disabled_style:
		background.add_theme_stylebox_override("panel", disabled_style)
	if click_button:
		click_button.disabled = true
		click_button.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_pressed() -> void:
	if _empty:
		return
	clicked.emit(_match_id, _entry)