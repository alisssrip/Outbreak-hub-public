extends Node

const APP_ID := "1531314040272322640"
const TICK := 1.0
const MIN_INTERVAL := 5.0
const INFECTION_INTERVAL := 15.0
const ASSET_LARGE := "logo"
const ASSET_TEXT := "Outbreak Revival"

var _ipc := DiscordIPC.new()
var _accum := 0.0
var _since_push := 0.0
var _last_key := ""
var _volatile := false
var _session_since := 0
var _enabled := false

func _ready() -> void:
	if APP_ID.is_empty():
		Log.d("[discord] no app id, presence disabled")
		return
	_enabled = true
	_session_since = int(Time.get_unix_time_from_system())
	_ipc.start(APP_ID)

func _process(delta: float) -> void:
	if not _enabled:
		return
	_accum += delta
	_since_push += delta
	if _accum < TICK:
		return
	_accum = 0.0
	var act := _build() if _setting_on() else {}
	var key := _key(act)
	if key != _last_key:
		if _since_push < MIN_INTERVAL:
			return
	elif _since_push < INFECTION_INTERVAL:
		return
	_last_key = key
	_since_push = 0.0
	_ipc.set_activity(act)

func _key(act: Dictionary) -> String:
	if not _volatile:
		return JSON.stringify(act)
	var stable := act.duplicate(true)
	stable.erase("state")
	return JSON.stringify(stable)

func shutdown() -> void:
	if _enabled:
		_ipc.stop()
		
func _setting_on() -> bool:
	if SettingsManager.settings == null:
		return false
	return int(SettingsManager.settings.discord_presence) == 1

func _build() -> Dictionary:
	_volatile = false
	if not RpcClient.is_connected_to_server():
		return {}
	var uid : int = RpcModules.user.user_id
	if uid == 0:
		return {}
	var user : Dictionary = RpcModules.user_store.get_user(uid)
	var phase := str(user.get("phase", RpcModules.user.status))
	var act := {
		"assets": {"large_image": ASSET_LARGE, "large_text": ASSET_TEXT},
		"timestamps": {"start": _session_since}
	}
	match phase:
		"in_game":
			_volatile = true
			act["details"] = "%s - %s" % [IngameStatusFormat.level_name(int(user.get("level", 0))), _character_name()]
			act["state"] = tr("DISCORD_INFECTION") % RpcModules.ingame_status.get_infection()
		"in_game_menu", "lobby", "in_room":
			act["details"] = tr("DISCORD_IN_GAME")
			act["state"] = IngameStatusFormat.in_game_status(user, {})
		_:
			act["details"] = tr("DISCORD_IN_LAUNCHER")
			act["state"] = IngameStatusFormat.status_text(phase)
	if str(act.get("state", "")).is_empty():
		act.erase("state")
	return act

func _character_name() -> String:
	var name := RpcModules.ingame_status.get_character_name_without_costume()
	return name if not name.is_empty() else "?"
