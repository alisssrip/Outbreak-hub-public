class_name RpcInGameModule
extends RefCounted

var ctx
var _status: InGameStatusController

signal own_match_started()
signal own_match_ended()
signal own_match_cancelled()
signal own_room_entered()

var _last_own_phase := ""

func init(hndlr, status: InGameStatusController) -> void:
	ctx = hndlr
	_status = status
	_status.infection_synced.connect(_on_infection_synced)
	_status.time_started.connect(_on_time_started)
	_status.time_stopped.connect(_on_time_stopped)
	RpcClient.event_received.connect(_on_own_phase)


func _on_infection_synced(value: float) -> void:
	if not RpcClient.is_connected_to_server(): return
	RpcClient.call_rpc("ingame.reportInfection", {"infection": value})

func _on_own_phase(method: String, params: Dictionary) -> void:
	if method != "friend.statusChanged": return
	if int(params.get("userId", 0)) != ctx.user.user_id: return
	var phase := str(params.get("phase", ""))
	if phase == _last_own_phase: return
	var previous := _last_own_phase
	_last_own_phase = phase
	match phase:
		"in_game":
			Log.d("[phase] in_game")
			RpcClient.call_rpc("presence.setBase", {"phase": "in_game"})
			own_match_started.emit()
		"in_room":
			Log.d("[phase] in_room")
			if previous == "in_game":
				Log.d("[phase] match ended to room")
				own_match_ended.emit()
			own_room_entered.emit()
		"lobby":
			Log.d("[phase] lobby")
			if previous == "in_game":
				own_match_ended.emit()
			else:
				Log.d("[phase] left room, no record")
				own_match_cancelled.emit()


func set_base(phase: String) -> void:
	RpcClient.call_rpc("presence.setBase", {"phase": phase})

func _on_time_started() -> void:
	if not RpcClient.is_connected_to_server(): return
	RpcClient.call_rpc("ingame.reportInfectionPause", {"paused": false})

func _on_time_stopped() -> void:
	if not RpcClient.is_connected_to_server(): return
	RpcClient.call_rpc("ingame.reportInfectionPause", {"paused": true})