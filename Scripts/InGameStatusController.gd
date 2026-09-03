class_name InGameStatusController
extends RefCounted

signal infection_changed(value: float)
signal infection_synced(value: float)
signal infection_stopped()
signal time_started()
signal time_stopped()
signal match_info(data: Dictionary)
signal match_ended(record: Dictionary)
signal record_finalized(record: Dictionary)

const INFECTION_PER_SEC := 0.02
const POLL_SEC := 0.5
const INFECTION_PER_POLL := INFECTION_PER_SEC * POLL_SEC
const STALL_POLLS_BEFORE_MANUAL := 4
const INFECTION_MAX := 100.0
const ZERO_POLLS_TO_ACCEPT := 2
const FPS := 30.0

const DEBUG_TRACE := false

var _pine: PCSX2_Pine
var _active := false
var _infection := 0.0
var _infection_last_real := -1.0
var _infection_stall := 0
var _infection_manual := false
var _frames_last := -1
var _time_real := 0.0
var _time_running := false
var _secure_time := 0.0
var _state := 0
var _last_known_state := 0
var _hits := 0
var _shots := 0
var _survivors := 0
var _points := 0
var _progress_raw := 0
var _finalized := false
var _zero_polls : Dictionary = {}
var _character := -1
var _scenario := -1
var _difficulty := -1
var _friendly_fire := 0

var charactersDic: Dictionary = {
	0: "Kevin",
	1: "Kevin",
	2: "Mark",
	3: "Marl",
	4: "Jim",
	5: "Jim",
	6: "George",
	7: "George",
	8: "David",
	9: "David",
	10: "Alyssa",
	11: "Alyssa",
	12: "Alyssa",
	13: "Yoko",
	14: "Yoko",
	15: "Yoko",
	16: "Cindy",
	17: "Cindy",
	18: "Cindy"
}

func init(hndlr) -> void:
	_pine = Pcsx2Manager.pine
	_pine.init(hndlr)
	_pine.infection_read.connect(_on_infection_read)
	_pine.frames_read.connect(_on_frames_read)
	_pine.state_read.connect(_on_state_read)
	_pine.hits_read.connect(_on_hits_read)
	_pine.shots_read.connect(_on_shots_read)
	_pine.survivors_read.connect(_on_survivors_read)
	_pine.points_read.connect(_on_points_read)
	_pine.progress_read.connect(_on_progress_read)
	_pine.config_read.connect(_on_config_read)

func start_match() -> void:
	if _active:
		Log.d("[match] previous still open, closing it")
		_finalize()
	_active = true
	_reset()
	_pine.start()

func on_match_started() -> void:
	if _pine:
		_pine.lock_config()

func stop_match() -> void:
	if not _active:
		return
	_active = false
	_pine.stop()

func end_match() -> void:
	if not _active:
		return
	_finalize()

func get_infection() -> float:
	return _infection

func get_time() -> float:
	return _time_real

func get_character() -> int:
	return _character

func get_character_name_without_costume() -> String: return charactersDic.get(get_character(), "")

func _reset() -> void:
	_infection = 0.0
	_infection_last_real = -1.0
	_infection_stall = 0
	_infection_manual = false
	_frames_last = -1
	_time_real = 0.0
	_time_running = false
	_secure_time = 0.0
	_state = 0
	_last_known_state = 0
	_hits = 0
	_shots = 0
	_survivors = 0
	_points = 0
	_progress_raw = 0
	_zero_polls.clear()
	_finalized = false
	_character = -1
	_scenario = -1
	_difficulty = -1
	_friendly_fire = 0

func _on_state_read(state: int) -> void:
	_state = _latch("state", _state, state)
	if _state != PCSX2_Pine.STATE_UNKNOWN:
		_last_known_state = _state

func _on_hits_read(total: int) -> void:
	_hits = _latch("hits", _hits, total)

func _on_shots_read(total: int) -> void:
	_shots = _latch("shots", _shots, total)

func _on_survivors_read(total: int) -> void:
	_survivors = _latch("survivors", _survivors, total)

func _on_points_read(total: int) -> void:
	_points = _latch("points", _points, total)

func _on_progress_read(raw: int) -> void:
	_progress_raw = _latch("progress", _progress_raw, raw)

func _on_config_read(character: int, scenario: int, difficulty: int, friendly_fire: int) -> void:
	var is_clear := (character == 0x00 or character == 0xFF or character < 0)
	var have_valid := _character > 0
	if is_clear and have_valid:
		return
	_character = character
	_scenario = scenario
	_difficulty = difficulty
	_friendly_fire = friendly_fire
	match_info.emit({"character": character, "scenario": scenario})

func _on_frames_read(frames: int) -> void:
	if frames == 0:
		if _time_running:
			_time_running = false
			time_stopped.emit()
		_frames_last = 0
		return
	if _frames_last < 0:
		_frames_last = frames
		_time_real = frames / FPS
		_secure_time = _time_real
		return
	var delta := frames - _frames_last
	_frames_last = frames
	if delta > 0:
		_time_real = frames / FPS
		_secure_time = _time_real
		if not _time_running:
			_time_running = true
			time_started.emit()
	elif _time_running:
		_time_running = false
		time_stopped.emit()

func _on_infection_read(real: float) -> void:
	if not _time_running:
		if _infection_manual:
			_infection_manual = false
			infection_stopped.emit()
		return
	if _infection_last_real < 0.0:
		_set_infection_real(real)
		return
	if not is_equal_approx(real, _infection_last_real):
		_set_infection_real(real)
		return
	_infection_stall += 1
	if _infection_stall >= STALL_POLLS_BEFORE_MANUAL:
		_infection_manual = true
		var capped : float = min(_infection + INFECTION_PER_POLL, INFECTION_MAX)
		if is_equal_approx(capped, _infection):
			return
		_infection = capped
		infection_changed.emit(_infection)

func _set_infection_real(real: float) -> void:
	_infection_last_real = real
	_infection = real
	_infection_stall = 0
	_infection_manual = false
	infection_changed.emit(real)
	infection_synced.emit(real)

func _has_real_match() -> bool:
	if _character > 0:
		return true
	if _secure_time >= 1.0:
		return true
	if _last_known_state != 0:
		return true
	return false

func _compute_cleared() -> bool:
	if _survivors < 1:
		return false
	if _last_known_state == PCSX2_Pine.STATE_DEAD:
		return false
	return true

func _finalize() -> void:
	if _finalized:
		return
	if not _has_real_match():
		Log.d("[record] skip finalize, no real match")
		stop_match()
		return
	_finalized = true
	if _time_running:
		_time_running = false
		time_stopped.emit()
	var record := {
		"character": _character,
		"scenario": _scenario,
		"difficulty": _difficulty,
		"timeSeconds": int(round(_secure_time)),
		"infection": int(round(_infection * 100.0)),
		"hits": _hits,
		"shots": _shots,
		"survivors": _survivors,
		"points": _points,
		"cleared": _compute_cleared(),
		"finalState": _last_known_state,
		"progressRaw": _progress_raw,
		"friendlyFire": bool(_friendly_fire)
	}
	Log.d("[record] %s" % JSON.stringify(record))
	match_ended.emit(record)
	record_finalized.emit(record)
	stop_match()

func _latch(key: String, current: int, incoming: int) -> int:
	if incoming != 0:
		_zero_polls[key] = 0
		return incoming
	if current == 0:
		return 0
	var seen : int = int(_zero_polls.get(key, 0)) + 1
	_zero_polls[key] = seen
	if seen >= ZERO_POLLS_TO_ACCEPT:
		Log.d("[match] %s reset to 0" % key)
		return 0
	return current