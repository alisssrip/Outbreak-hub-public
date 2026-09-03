class_name MV_GameBreakdown_PlayerRow
extends Panel

const STATE_DEAD := 4

@export var nickname_label : Label
@export var character_label : Label
@export var infection_label : Label
@export var hits_label : Label
@export var shots_label : Label
@export var progress_label : Label
@export var points_label : Label
@export var status_label : Label
@export var character_icon : TextureRect
@export var empty_icon : Texture2D

func set_data(data: Dictionary) -> void:
	var ch : int = int(data.get("character", -1))
	nickname_label.text = str(data.get("nickname", "?"))
	character_label.text = OutbreakMeta.character_name(ch)
	infection_label.text = tr("BREAKDOWN_INFECTION") % (int(data.get("infection", 0)) / 100)
	hits_label.text = tr("BREAKDOWN_HITS") % int(data.get("hits", 0))
	shots_label.text = tr("BREAKDOWN_SHOTS") % int(data.get("shots", 0))
	progress_label.text = tr("BREAKDOWN_PROGRESS") % int(data.get("progressPct", 0))
	points_label.text = tr("BREAKDOWN_POINTS") % int(data.get("points", 0))
	_set_status(int(data.get("survived", 0)), int(data.get("finalState", 0)))
	if character_icon:
		var spr := _resolve_icon(ch)
		if spr != null:
			character_icon.texture = spr

func set_empty() -> void:
	nickname_label.text = "---"
	character_label.text = "---"
	infection_label.text = "---"
	hits_label.text = "---"
	shots_label.text = "---"
	progress_label.text = "---"
	points_label.text = "---"
	status_label.text = "---"
	status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	if character_icon and empty_icon != null:
		character_icon.texture = empty_icon

func _resolve_icon(ch: int) -> Texture2D:
	var base_name := OutbreakMeta.character_name(ch)
	for c in LauncherController.instance.character.store:
		if c.character_name == base_name:
			return c.record
	return null

func _set_status(survived: int, final_state: int) -> void:
	if survived >= 1:
		status_label.text = tr("RESULTS_SURVIVED")
		status_label.add_theme_color_override("font_color", Color(0.459, 0.902, 0.584))
	elif final_state == STATE_DEAD:
		status_label.text = tr("RESULTS_DEATH")
		status_label.add_theme_color_override("font_color", Color(0.9, 0.459, 0.459))
	else:
		status_label.text = tr("RESULTS_ABANDONED")
		status_label.add_theme_color_override("font_color", Color(0.9, 0.459, 0.459))