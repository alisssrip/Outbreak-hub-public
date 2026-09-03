class_name RpcUserStore
extends RefCounted

signal user_updated(user_id: int, fields: Array)
signal user_loaded(user_id: int)
signal users_bulk_loaded(user_ids: Array)
signal ingame_updated(user_id: int)

var RESOURCE_BASE := Endpoints.resource_base()
const PRESENCE_KEYS := ["phase", "area", "room", "level", "difficulty"]

var _users : Dictionary = {}
var _textures : Dictionary = {}
var _loading_urls : Dictionary = {}
var _ingame : Dictionary = {}

func _init() -> void:
	RpcClient.event_received.connect(_on_event)

func get_user(user_id: int) -> Dictionary:
	var usergetted = _users.get(user_id, {})
	return usergetted

func has_user(user_id: int) -> bool:
	return _users.has(user_id)
	
func ensure_user(user_id: int, callback: Callable) -> void:
	var data := get_user(user_id)
	if not data.is_empty():
		callback.call(data)
		return
	RpcModules.user.fetch_profile(user_id, func(result):
		if result == null:
			callback.call({})
			return
		set_user(user_id, result)
		callback.call(get_user(user_id))
	)

func get_avatar(user_id: int) -> Texture2D:
	var url : String = _users.get(user_id, {}).get("avatarUrl", "")
	if url.is_empty(): return null
	return _textures.get(url, null)

func set_user(user_id: int, data: Dictionary) -> void:
	var normalized : Dictionary = {}
	for k in data:
		normalized[k] = data[k]
	normalized["userId"] = user_id
	var existing : Dictionary = _users.get(user_id, {})
	for k in PRESENCE_KEYS:
		if not normalized.has(k) and existing.has(k):
			normalized[k] = existing[k]
	var is_new := not _users.has(user_id)
	var old_avatar : String = existing.get("avatarUrl", "")
	_users[user_id] = normalized
	if is_new:
		user_loaded.emit(user_id)
	user_updated.emit(user_id, normalized.keys())
	var new_avatar : String = str(normalized.get("avatarUrl", ""))
	if not new_avatar.is_empty() and new_avatar != old_avatar:
		_request_avatar(user_id, new_avatar)

func set_users_bulk(users_data: Dictionary) -> void:
	var ids : Array = []
	for uid in users_data:
		var iid := int(uid)
		var data : Dictionary = users_data[uid]
		var existing = _users.get(iid, {})
		if existing.has("phase"):
			data = data.duplicate()
			data["phase"] = existing["phase"]
		set_user(iid, data)
		ids.append(iid)
	users_bulk_loaded.emit(ids)

func update_user(user_id: int, fields: Dictionary) -> void:
	if not _users.has(user_id):
		_users[user_id] = {"userId": user_id}
	var changed : Array = []
	var old_avatar : String = _users[user_id].get("avatarUrl", "")
	for k in fields:
		if _users[user_id].get(k) != fields[k]:
			_users[user_id][k] = fields[k]
			changed.append(k)
	if not changed.is_empty():
		user_updated.emit(user_id, changed)
	var new_avatar : String = str(_users[user_id].get("avatarUrl", ""))
	if not new_avatar.is_empty() and new_avatar != old_avatar:
		_request_avatar(user_id, new_avatar)

func clear() -> void:
	_users.clear()
	_textures.clear()
	_loading_urls.clear()
	_ingame.clear()

func _request_avatar(user_id: int, url: String) -> void:
	if _textures.has(url): return
	if _loading_urls.has(url):
		_loading_urls[url].append(user_id)
		return
	_loading_urls[url] = [user_id]
	var full_url := RESOURCE_BASE + url
	NetworkHandler.profile.load_image(full_url, func(texture):
		if texture != null:
			_textures[url] = texture
		var waiting_ids : Array = _loading_urls.get(url, [])
		_loading_urls.erase(url)
		for uid in waiting_ids:
			user_updated.emit(int(uid), ["_avatar_texture"])
	)
	
func get_ingame(user_id: int) -> Dictionary:
	return _ingame.get(user_id, {})

func is_ingame(user_id: int) -> bool:
	return _ingame.has(user_id)

func update_ingame(user_id: int, fields: Dictionary) -> void:
	if not _ingame.has(user_id):
		_ingame[user_id] = {}
	for k in fields:
		_ingame[user_id][k] = fields[k]
	ingame_updated.emit(user_id)

func clear_ingame(user_id: int) -> void:
	if _ingame.erase(user_id):
		ingame_updated.emit(user_id)

func _on_event(method: String, params: Dictionary) -> void:
	if method == "friend.statusChanged":
		Log.d("[store] statusChanged uid=%s phase=%s" % [str(params.get("userId")), str(params.get("phase"))])
	match method:
		"friend.statusChanged":
			var uid := int(params["userId"])
			var phase := str(params.get("phase", "offline"))
			var fields := {
				"phase": phase,
				"status": "offline" if phase == "offline" else "online"
			}
			if params.has("area"): fields["area"] = int(params["area"])
			if params.has("room"): fields["room"] = int(params["room"])
			if params.has("level"): fields["level"] = int(params["level"])
			if params.has("difficulty"): fields["difficulty"] = int(params["difficulty"])
			update_user(uid, fields)
			if phase != "in_game":
				clear_ingame(uid)
		"ingame.characterUpdated":
			update_ingame(int(params["userId"]), {"character": int(params["character"])})
		