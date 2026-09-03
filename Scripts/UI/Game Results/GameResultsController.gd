class_name GameResultsController
extends Node

@export var panel: Control
@export var closeButton: Button
@export var scenario: GameResultsSingleField
@export var character: GameResultsSingleField
@export var difficulty: GameResultsSingleField
@export var shootsTimeProgress: GameResultsTripleField
@export var costumeFF: GameResultsDobleField
@export var infection: GameResultsSingleField
@export var points: GameResultsSingleField
@export var status: GameResultsSingleField
@export var hits: GameResultsSingleField
@export var record: GameResultsSingleField
@export var rank: GameResultsSingleField
@export var normalColor: Color
@export var goldenColor: Color
@export var rowDelay: float = 0.15
@export var rankExtraDelay: float = 0.4

const STATE_DEAD := 4

var _rows: Array = []

func _ready() -> void:
	_rows = [scenario, character, difficulty, shootsTimeProgress, costumeFF, infection, points, status, hits, record]
	if panel:
		panel.visible = false
	if closeButton:
		closeButton.pressed.connect(hide_results)

func show_results(record_data: Dictionary, response: Dictionary = {}, is_detail: bool = false) -> void:
	var ch : int = record_data.get("character", -1)
	var sc : int = record_data.get("scenario", -1)
	var df : int = record_data.get("difficulty", 0)
	var time_s : int = record_data.get("timeSeconds", 0)
	var inf : int = record_data.get("infection", 0)
	var hits_n : int = record_data.get("hits", 0)
	var shots_n : int = record_data.get("shots", 0)
	var survivors_n : int = record_data.get("survivors", 0)
	var points_n : int = record_data.get("points", 0)
	var final_state : int = record_data.get("finalState", 0)
	var progress_raw : int = record_data.get("progressRaw", 0)
	var ff : bool = int(record_data.get("friendlyFire", 0)) != 0

	var is_new_best : bool = response.get("isNewBest", false)
	var points_diff : int = response.get("pointsDiff", 0)
	var progress_pct : int = _progress_pct(sc, progress_raw)

	_set_scenario(sc)
	_set_character(ch)
	_set_difficulty(df)
	_set_shots_time_progress(shots_n, time_s, progress_pct)
	_set_costume_ff(ch, ff)
	_set_infection(inf)
	_set_points(points_n, points_diff, is_new_best)
	_set_status(survivors_n, final_state)
	_set_hits(hits_n)
	_set_record(is_new_best)
	if record_data.has("rank"):
		_set_rank(record_data["rank"])

	if is_detail:
		_set_detail_button_text()
		_open_panel_instant()
	else:
		_set_close_button_text(is_new_best)
		_open_panel()
		_animate_rows()

func _progress_pct(sc: int, raw: int) -> int:
	if raw <= 0:
		return 0
	var maxes := {0: 33, 1: 33, 2: 25, 3: 33, 4: 50}
	var m : int = maxes.get(sc, 33)
	var pct : float = float(raw) / float(m) * 100.0 + 1.0
	return int(min(pct, 100.0))

func _open_panel() -> void:
	if panel:
		panel.visible = true
	for r in _rows:
		if r:
			r.visible = false
	if rank:
		rank.visible = false

func _open_panel_instant() -> void:
	if panel:
		panel.visible = true
	for r in _rows:
		if r:
			r.visible = true
	if rank:
		rank.visible = true

func _animate_rows() -> void:
	for i in _rows.size():
		var r = _rows[i]
		if r == null:
			continue
		await get_tree().create_timer(rowDelay).timeout
		r.visible = true
	if rank:
		await get_tree().create_timer(rankExtraDelay).timeout
		rank.visible = true

func hide_results() -> void:
	if panel:
		panel.visible = false

func _set_close_button_text(new_best: bool) -> void:
	if closeButton:
		closeButton.text = tr("RESULTS_CLOSE_BEST") if new_best else tr("RESULTS_CLOSE_OK")

func _set_detail_button_text() -> void:
	if closeButton:
		closeButton.text = tr("COMMON_CLOSE")

func _set_scenario(id: int) -> void:
	scenario._set_field_text(OutbreakMeta.scenario_name(id))

func _set_character(id: int) -> void:
	character._set_field_text(OutbreakMeta.character_name(id))

func _set_difficulty(id: int) -> void:
	difficulty._set_field_text(OutbreakMeta.difficulty_name(id))
	difficulty._set_field_color(OutbreakMeta.difficulty_color(id))

func _set_shots_time_progress(shots_n: int, time_s: int, progress_pct: int) -> void:
	shootsTimeProgress.set_field_text(1, tr("RESULTS_SHOTS") % shots_n)
	shootsTimeProgress.set_field_text(2, _format_time(time_s))
	shootsTimeProgress.set_field_text(3, tr("RESULTS_PROGRESS") % progress_pct)

func _set_costume_ff(ch: int, ff: bool) -> void:
	costumeFF.set_field_text(1, tr("RESULTS_COSTUME") % OutbreakMeta.character_costume(ch))
	costumeFF.set_field_text(2, tr("RESULTS_FF") % (tr("COMMON_ON") if ff else tr("COMMON_OFF")))

func _set_infection(infectionResult: int) -> void:
	var pct : float = float(infectionResult) / 100.0
	infection._set_field_text(tr("RESULTS_INFECTION") % pct)

func _set_points(totalPoints: int, pointsDiff: int, new_best: bool) -> void:
	if new_best and pointsDiff > 0:
		points._set_field_text(tr("RESULTS_POINTS_BEST") % [totalPoints, pointsDiff])
	else:
		points._set_field_text(tr("RESULTS_POINTS") % totalPoints)

func _set_status(survivors_n: int, final_state: int) -> void:
	if survivors_n >= 1:
		status._set_field_text(tr("RESULTS_SURVIVED"))
		status._set_field_color(Color(0.459, 0.902, 0.584))
	elif final_state == STATE_DEAD:
		status._set_field_text(tr("RESULTS_DEATH"))
		status._set_field_color(Color(0.9, 0.459, 0.459))
	else:
		status._set_field_text(tr("RESULTS_ABANDONED"))
		status._set_field_color(Color(0.9, 0.459, 0.459))

func _set_hits(hitsCount: int) -> void:
	if hitsCount == 0:
		hits._set_field_text(tr("RESULTS_NO_HIT"))
		hits._set_field_color(goldenColor)
	else:
		hits._set_field_text(tr("RESULTS_HITS") % hitsCount)
		hits._set_field_color(normalColor)

func _set_record(recordAchieved: bool) -> void:
	if recordAchieved:
		record._set_field_text(tr("RESULTS_NEW_RECORD"))
		record._set_field_color(goldenColor)
	else:
		record._set_field_text(tr("RESULTS_NO_RECORD"))
		record._set_field_color(normalColor)

func _set_rank(rankID: int) -> void:
	rank._set_field_text(OutbreakMeta.rank_name(rankID))
	rank._set_field_color(OutbreakMeta.rank_color(rankID))

func _format_time(total_seconds: int) -> String:
	var m : int = total_seconds / 60
	var s : int = total_seconds % 60
	return "%02d:%02d" % [m, s]