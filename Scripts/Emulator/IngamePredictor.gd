class_name IngamePredictor
extends RefCounted

const INFECTION_PER_SEC := 0.02
const UPDATE_INTERVAL := 0.5
const INFECTION_MAX := 100.0

var _store: RpcUserStore
var _state : Dictionary = {}
var _accum := 0.0

func init(store: RpcUserStore) -> void:
	_store = store
	RpcClient.event_received.connect(_on_event)

func _on_event(method: String, params: Dictionary) -> void:
	match method:
		"friend.statusChanged":
			var uid := int(params["userId"])
			var phase := str(params.get("phase", "offline"))
			if phase == "in_game":
				_set_time(uid, float(params.get("time", 0.0)))
			else:
				_stop(uid)
		"ingame.infectionSynced":
			_set_infection(int(params["userId"]), float(params["infection"]))
		"ingame.infectionPause":
			_set_paused(int(params["userId"]), bool(params["paused"]))

func _set_paused(uid: int, paused: bool) -> void:
	_ensure(uid)
	var now := Time.get_ticks_msec() / 1000.0
	if paused:
		_state[uid]["base"] = min(_state[uid]["base"] + INFECTION_PER_SEC * (now - _state[uid]["sync_time"]), INFECTION_MAX)
		_state[uid]["sync_time"] = now
		_state[uid]["paused"] = true
	else:
		_state[uid]["sync_time"] = now
		_state[uid]["paused"] = false

func _ensure(uid: int) -> void:
	if not _state.has(uid):
		var now := Time.get_ticks_msec() / 1000.0
		_state[uid] = {"base": 0.0, "sync_time": now, "since": now, "paused": false}

func _set_time(uid: int, base_time: float) -> void:
	_ensure(uid)
	var now := Time.get_ticks_msec() / 1000.0
	_state[uid]["since"] = now - base_time

func _set_infection(uid: int, value: float) -> void:
	_ensure(uid)
	var now := Time.get_ticks_msec() / 1000.0
	_state[uid]["base"] = value
	_state[uid]["sync_time"] = now

func _stop(uid: int) -> void:
	_state.erase(uid)

func tick(delta: float) -> void:
	_accum += delta
	if _accum < UPDATE_INTERVAL:
		return
	_accum = 0.0
	if _state.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	for uid in _state:
		var s = _state[uid]
		var infection : float = s["base"]
		if not s.get("paused", false):
			infection = min(infection + INFECTION_PER_SEC * (now - s["sync_time"]), INFECTION_MAX)
		var elapsed : float = now - s["since"]
		_store.update_ingame(int(uid), {"infection": infection, "time": elapsed})