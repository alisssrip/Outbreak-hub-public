class_name MV_GameBreakdown
extends Node

@export var panel : Control
@export var close_button : Button
@export var scenario_label : Label
@export var difficulty_label : Label
@export var time_label : Label
@export var date_label : Label
@export var total_progress_label : Label
@export var final_points_label : Label
@export var player_rows : Array[MV_GameBreakdown_PlayerRow] = []

func _ready() -> void:
	if panel:
		panel.visible = false
	if close_button:
		close_button.pressed.connect(hide_breakdown)

func show_breakdown(data: Dictionary) -> void:
	var sc : int = int(data.get("scenario", 0))
	var df : int = int(data.get("difficulty", 0))
	scenario_label.text = OutbreakMeta.scenario_name(sc)
	difficulty_label.text = OutbreakMeta.difficulty_name(df)

	var players : Array = data.get("players", [])
	for i in player_rows.size():
		var row := player_rows[i]
		if row == null:
			continue
		if i < players.size():
			row.set_data(players[i])
		else:
			row.set_empty()

	total_progress_label.text = tr("BREAKDOWN_TOTAL_PROGRESS") % _max_progress(players)
	final_points_label.text = tr("BREAKDOWN_FINAL_POINTS") % _total_points(players)
	time_label.text = tr("BREAKDOWN_TIME") % _best_time(players)
	date_label.text = _format_date(str(data.get("closedAt", data.get("startedAt", ""))))

	if panel:
		panel.visible = true

func hide_breakdown() -> void:
	if panel:
		panel.visible = false

func _total_points(players: Array) -> int:
	var total := 0
	for p in players:
		total += int(p.get("points", 0))
	return total

func _max_progress(players: Array) -> int:
	var best := 0
	for p in players:
		var pr := int(p.get("progressPct", 0))
		if pr > best:
			best = pr
	return best

func _best_time(players: Array) -> String:
	var best := -1
	var longest := -1
	for p in players:
		var t := int(p.get("timeSeconds", 0))
		if t > longest:
			longest = t
		if bool(p.get("survived", false)) and (best < 0 or t < best):
			best = t
	if best >= 0:
		return _format_time(best)
	if longest >= 0:
		return _format_time(longest)
	return "--:--"

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