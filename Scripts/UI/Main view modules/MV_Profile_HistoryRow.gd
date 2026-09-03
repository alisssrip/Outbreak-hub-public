class_name MV_Profile_HistoryRow
extends Panel

signal clicked(match_id: int, entry: Dictionary)

@export var character_icon : TextureRect
@export var background : TextureRect
@export var name_label : Label
@export var scenario_label : Label
@export var scenario_difficulty_label : Label
@export var time_label : Label
@export var infection_label : Label
@export var points_label : Label
@export var date_label : Label
@export var rank_label : Label
@export var click_button : Button
@export var scenario_backgrounds : Array[MV_Profile_RecordScenarioBackground] = []

var _match_id : int = -1
var _entry : Dictionary = {}

func _ready() -> void:
	if click_button:
		click_button.pressed.connect(_on_pressed)

func set_data(data: Dictionary) -> void:
	var ch : int = int(data.get("character", -1))
	var sc : int = int(data.get("scenario", 0))
	_match_id = int(data.get("id", -1))
	_entry = data
	name_label.text = OutbreakMeta.character_name(ch)
	scenario_label.text = OutbreakMeta.scenario_name(sc)
	scenario_difficulty_label.text = OutbreakMeta.difficulty_name(int(data.get("difficulty", 0)))
	time_label.text = tr("HISTORY_TIME") % _format_time(int(data.get("timeSeconds", 0)))
	infection_label.text = tr("HISTORY_INFECTION") % (int(data.get("infection", 0)) / 100)
	points_label.text = tr("HISTORY_POINTS") % int(data.get("points", 0))
	date_label.text = _format_date(str(data.get("createdAt", "")))
	rank_label.text = tr("HISTORY_RANK") % _rank_to_string(data.get("rank"))
	if character_icon:
		var spr := _resolve_icon(ch)
		if spr != null:
			character_icon.texture = spr
	_set_background(sc)

func _set_background(sc: int) -> void:
	if background == null:
		return
	var sc_name := OutbreakMeta.scenario_name(sc)
	for bg in scenario_backgrounds:
		if bg.scenario_name == sc_name:
			background.texture = bg.background
			return

func _resolve_icon(ch: int) -> Texture2D:
	var base_name := OutbreakMeta.character_name(ch)
	for c in LauncherController.instance.character.store:
		if c.character_name == base_name:
			return c.record
	return null

func _rank_to_string(value) -> String:
	if value == null:
		return "-"
	return OutbreakMeta.rank_name(int(value))

func _on_pressed() -> void:
	if _match_id < 0:
		return
	clicked.emit(_match_id, _entry)

func _format_time(total_seconds: int) -> String:
	var m : int = total_seconds / 60
	var s : int = total_seconds % 60
	return "%02d:%02d" % [m, s]

func _format_date(iso: String) -> String:
	if iso == "" or iso == "null":
		return "--/--/----"
	var date_part := iso.split("T")[0]
	var parts := date_part.split("-")
	if parts.size() < 3:
		return date_part
	return "%s/%s/%s" % [parts[2], parts[1], parts[0]]
