class_name MV_ProfileModule
extends MV_BaseModule

@export var resume_system        : MV_Profile_ResumeSystem
@export var stats_system         : MV_Profile_StatsSystem
@export var records_system       : MV_Profile_RecordsSystem
@export var achievements_system  : MV_Profile_AchievementsSystem
@export var history_system : MV_Profile_HistorySystem

var _target_user_id : int = 0
var _setting_status : bool = false
var _is_open : bool = false
var _opening_breakdown : bool = false

func _ready() -> void:
	resume_system.status_changed.connect(_on_status_changed)
	resume_system.bio_changed.connect(_on_bio_changed)
	resume_system.add_friend_requested.connect(_on_add_friend)
	resume_system.remove_friend_requested.connect(_on_remove_friend)
	RpcModules.user_store.user_updated.connect(_on_user_updated)
	RpcModules.friend.friend_updated.connect(_on_friend_list_changed)
	records_system.level_clicked.connect(_on_record_level_clicked)
	history_system.row_clicked.connect(_on_history_clicked)

func initState(hndlr: MainViewComponentSystem) -> MV_BaseModule:
	super.initState(hndlr)
	return self

func set_target(user_id: int) -> void:
	if _is_open and user_id == _target_user_id:
		return
	_target_user_id = user_id
	if _is_open:
		_apply_mode()
		_load_profile()


func startState() -> void:
	_open_window()
	_is_open = true
	if _target_user_id == 0:
		_target_user_id = RpcModules.user.user_id
	_reset_sections()
	_apply_mode()
	_load_profile()

func _reset_sections() -> void:
	for section in get_tree().get_nodes_in_group("ProfileSection"):
		section.reset_state()

func updateState() -> void:
	return

func exitState() -> void:
	_close_window()
	_is_open = false
	_target_user_id = 0

func _apply_mode() -> void:
	var is_own : bool = _target_user_id == RpcModules.user.user_id
	resume_system.set_editable(is_own)
	if not is_own:
		_load_relation()

func _load_relation() -> void:
	RpcClient.call_rpc("friend.getRelation", {"targetId": _target_user_id}, func(result, err):
		if err: return
		var relation_str := str(result.get("relation", "none"))
		resume_system.set_relation(_parse_relation(relation_str))
	)

func _parse_relation(s: String) -> MV_Profile_ResumeSystem.Relation:
	match s:
		"friend":           return MV_Profile_ResumeSystem.Relation.FRIEND
		"pending_outgoing": return MV_Profile_ResumeSystem.Relation.PENDING_OUTGOING
		"pending_incoming": return MV_Profile_ResumeSystem.Relation.PENDING_INCOMING
		_:                  return MV_Profile_ResumeSystem.Relation.NONE

func _on_add_friend() -> void:
	if _target_user_id == 0: return
	if _target_user_id == RpcModules.user.user_id: return
	resume_system.set_relation(MV_Profile_ResumeSystem.Relation.PENDING_OUTGOING)
	RpcClient.call_rpc("friend.sendRequest", {"targetId": _target_user_id}, func(result, err):
		if err or (result.get("ok", false) == false):
			resume_system.set_relation(MV_Profile_ResumeSystem.Relation.NONE)
			return
	)

func _load_profile() -> void:
	if _target_user_id == 0:
		push_warning("profile load skipped: no target")
		return
	RpcModules.user.fetch_profile(_target_user_id, func(result):
		if result == null:
			push_warning("profile load failed: user not found")
			return
		RpcModules.user_store.set_user(_target_user_id, result)
		_render_from_store()
	)
	_load_records()
	_load_history()
	achievements_system.load_achievements(_target_user_id)

func _load_records() -> void:
	NetworkHandler.records.get_records(_target_user_id, func(code, data):
		if data == null: return
		var records : Array[MV_Profile_RecordData] = []
		for item in data.get("records", []):
			var record := MV_Profile_RecordData.new()
			record.char_base     = str(item.get("charBase", ""))
			record.cleared       = bool(item.get("cleared", false))
			record.difficulty    = _header_difficulty(item.get("difficulty"))
			record.total_time    = _format_time(int(item.get("totalTime", 0)))
			record.avg_infection = int(item.get("avgInfection", 0))
			record.rank          = _header_rank(item.get("rank"))
			var levels : Array[MV_Profile_RecordLevelData] = []
			for sc in item.get("scenarios", []):
				var lvl := MV_Profile_RecordLevelData.new()
				lvl.scenario      = int(sc.get("scenario", 0))
				lvl.scenario_name = OutbreakMeta.scenario_name(int(sc.get("scenario", 0)))
				lvl.difficulty    = OutbreakMeta.difficulty_name(int(sc.get("difficulty", 0)))
				lvl.time          = _format_time(int(sc.get("timeSeconds", 0)))
				lvl.rank          = _level_rank(sc.get("rank"))
				lvl.progress      = int(sc.get("progressPct", 0))
				lvl.date = _format_date(str(sc.get("createdAt", "")))
				lvl.infection     = int(sc.get("infection", 0)) / 100
				lvl.points        = int(sc.get("points", 0))
				lvl.match_id      = int(sc.get("matchId", 0))
				lvl.raw           = sc
				lvl.empty         = false
				levels.append(lvl)
			record.levels = levels
			records.append(record)
		records_system.set_records(records)
	)


func _format_date(iso: String) -> String:
	if iso == "" or iso == "null":
		return "--/--/----"
	var date_part := iso.split("T")[0]
	var parts := date_part.split("-")
	if parts.size() < 3:
		return date_part
	return "%s/%s/%s" % [parts[2], parts[1], parts[0]]
func _header_difficulty(value) -> String:
	if value is String:
		return value
	return OutbreakMeta.difficulty_name(int(value))

func _header_rank(value) -> String:
	if value is String:
		return value
	return OutbreakMeta.rank_name(int(value))

func _level_rank(value) -> String:
	if value == null:
		return "-"
	return OutbreakMeta.rank_name(int(value))

func _render_from_store() -> void:
	var data : Dictionary = RpcModules.user_store.get_user(_target_user_id)
	if data.is_empty(): return
	resume_system.set_username(str(data.get("nickname", "")))
	resume_system.set_bio(str(data.get("title", "")) if data.get("title") != null else "")
	var phase_str := str(data.get("phase", ""))
	if phase_str == "":
		if data.has("isOnline") and not bool(data.get("isOnline", false)):
			phase_str = "offline"
		else:
			phase_str = str(data.get("status", "offline"))
	resume_system.set_status(_parse_status(phase_str))
	var muc = data.get("mostUsedChar", null)
	stats_system.set_stats(
		int(muc) if muc != null else -1,
		int(data.get("playingTime", 0)),
		int(data.get("totalHits", 0)),
		int(data.get("totalShots", 0)),
		int(data.get("totalPoints", 0)),
		int(data.get("deaths", 0))
	)
	var texture = RpcModules.user_store.get_avatar(_target_user_id)
	if texture != null:
		resume_system.set_avatar(texture)

func _on_user_updated(uid: int, _fields: Array) -> void:
	if uid != _target_user_id: return
	_render_from_store()

func _on_friend_list_changed(_uid: int) -> void:
	if _target_user_id == 0: return
	if _target_user_id == RpcModules.user.user_id: return
	_load_relation()

func _on_favorite_char_changed(character: CharacterData) -> void:
	if _target_user_id != RpcModules.user.user_id: return
	NetworkHandler.profile.set_favorite_char(
		RpcModules.user.user_id,
		character.character_name,
		func(ok):
			if ok == null or not ok: return
			RpcModules.user_store.update_user(RpcModules.user.user_id, {"charFav": character.character_name})
	)

func _on_status_changed(status: MV_Profile_ResumeSystem.Status) -> void:
	if _setting_status: return
	if _target_user_id != RpcModules.user.user_id: return
	var status_str := _status_to_string(status)
	NetworkHandler.profile.set_status(RpcModules.user.user_id, status_str, func(data):
		if data == null: return
		RpcModules.user_store.update_user(RpcModules.user.user_id, {"status": status_str})
	)
	if RpcClient.is_connected_to_server():
		RpcModules.user.set_status(status_str)

func _on_bio_changed(new_bio: String) -> void:
	if _target_user_id != RpcModules.user.user_id: return
	NetworkHandler.profile.set_bio(RpcModules.user.user_id, new_bio, func(data):
		if data == null: return
		RpcModules.user_store.update_user(RpcModules.user.user_id, {"title": new_bio})
	)

func _on_remove_friend() -> void:
	if _target_user_id == 0: return
	if _target_user_id == RpcModules.user.user_id: return
	Popups_Controller.instance.show_confirm(tr("POPUP_REMOVE_FRIEND"), 
	func() -> void: 
		RpcModules.friend.remove(_target_user_id)
		resume_system.set_relation(MV_Profile_ResumeSystem.Relation.NONE)
	)

func _load_history() -> void:
	NetworkHandler.records.get_history(_target_user_id, func(code, data):
		if data == null: return
		var history : Array = data.get("history", [])
		history_system.set_history(history)
	)
 
func _on_record_level_clicked(match_id: int, entry: Dictionary) -> void:
	_resolve_and_open_breakdown(match_id, entry)

func _on_history_clicked(match_id: int, entry: Dictionary) -> void:
	_resolve_and_open_breakdown(match_id, entry)

func _resolve_and_open_breakdown(match_id: int, row: Dictionary) -> void:
	if _opening_breakdown:
		return
	_opening_breakdown = true
	NetworkHandler.records.get_match_entry(match_id, func(code, data):
		if data == null:
			_opening_breakdown = false
			return
		var gamenr = data.get("gamenr", null)
		if gamenr == null:
			LauncherController.instance.game_details.show_breakdown(_solo_breakdown(data, row))
			_opening_breakdown = false
			return
		NetworkHandler.records.get_match_detail(int(gamenr), func(code2, detail):
			if detail != null:
				LauncherController.instance.game_details.show_breakdown(detail)
			_opening_breakdown = false
		)
	)

func _resolve_nickname(data: Dictionary, uid: int) -> String:
	var from_entry := str(data.get("nickname", ""))
	if not from_entry.is_empty() and from_entry != "?":
		return from_entry
	if uid == RpcModules.user.user_id and not RpcModules.user.nickname.is_empty():
		return RpcModules.user.nickname
	var stored := str(RpcModules.user_store.get_user(uid).get("nickname", ""))
	if not stored.is_empty():
		return stored
	return "?"

func _pick(data: Dictionary, row: Dictionary, key: String, fallback):
	var value = data.get(key, null)
	if value != null:
		return value
	value = row.get(key, null)
	if value != null:
		return value
	return fallback

func _solo_breakdown(data: Dictionary, row: Dictionary) -> Dictionary:
	var created := str(_pick(data, row, "createdAt", ""))
	var cleared := bool(_pick(data, row, "cleared", false))
	var uid := int(_pick(data, row, "userId", _target_user_id))
	var player := {
		"userId": uid,
		"nickname": _resolve_nickname(data, uid),
		"character": int(_pick(data, row, "character", -1)),
		"survived": cleared,
		"finalState": int(_pick(data, row, "finalState", 0)),
		"timeSeconds": int(_pick(data, row, "timeSeconds", 0)),
		"infection": int(_pick(data, row, "infection", 0)),
		"hits": int(_pick(data, row, "hits", 0)),
		"shots": int(_pick(data, row, "shots", 0)),
		"points": int(_pick(data, row, "points", 0)),
		"progressPct": int(_pick(data, row, "progressPct", 0)),
		"friendlyFire": bool(_pick(data, row, "friendlyFire", false)),
		"createdAt": created
	}
	return {
		"scenario": int(_pick(data, row, "scenario", 0)),
		"difficulty": int(_pick(data, row, "difficulty", 0)),
		"totalPlayers": 1,
		"survivors": 1 if cleared else 0,
		"startedAt": created,
		"closedAt": created,
		"players": [player]
	}



func _parse_status(status_str: String) -> MV_Profile_ResumeSystem.Status:
	match status_str:
		"online":   return MV_Profile_ResumeSystem.Status.ONLINE
		"afk":      return MV_Profile_ResumeSystem.Status.AFK
		"busy":     return MV_Profile_ResumeSystem.Status.BUSY
		"in_game_menu", "lobby", "in_room", "in_game":
			return MV_Profile_ResumeSystem.Status.INGAME
		_:          return MV_Profile_ResumeSystem.Status.OFFLINE

func _status_to_string(status: MV_Profile_ResumeSystem.Status) -> String:
	match status:
		MV_Profile_ResumeSystem.Status.ONLINE: return "online"
		MV_Profile_ResumeSystem.Status.AFK:    return "afk"
		MV_Profile_ResumeSystem.Status.BUSY:   return "busy"
		_:                                      return "online"

func _format_time(seconds: int) -> String:
	if seconds >= 60000:
		return "%dM" % (seconds / 60)
	var minutes := seconds / 60
	var secs    := seconds % 60
	return "%02d:%02d" % [minutes, secs]
