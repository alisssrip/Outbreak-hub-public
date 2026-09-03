class_name RpcFriendModule
extends RefCounted

signal friend_updated(user_id: int)
signal friend_removed(user_id: int)
signal request_received(from_id: int)

var list : Dictionary = {}

func _init() -> void:
	RpcClient.event_received.connect(_on_event)

func _ready() -> void:
	RpcClient.connected.connect(_on_connected)

func _on_connected() -> void:
	load_friends()

func load_friends() -> void:
	RpcClient.call_rpc("friend.getList", {}, func(result, err):
		if err: return
		list.clear()
		for f in result["friends"]:
			var uid := int(f["userId"])
			f["userId"] = uid
			var existing := RpcModules.user_store.get_user(uid)
			if existing.has("phase"):
				f["phase"] = existing["phase"]
			elif not bool(f.get("isOnline", false)):
				f["phase"] = "offline"
			elif not f.has("phase"):
				f["phase"] = str(f.get("status", "offline"))
			list[uid] = f
			RpcModules.user_store.set_user(uid, f)
		friend_updated.emit(-1)
	)

func send_request(target_id: int) -> void:
	RpcClient.call_rpc("friend.sendRequest", {"targetId": target_id}, func(result, err):
		if err or not result["ok"]: return
		Log.d("Solicitud enviada")
	)

func accept_request(from_id: int) -> void:
	RpcClient.call_rpc("friend.accept", {"fromId": from_id}, func(result, err):
		if not err: load_friends()
	)

func remove(target_id: int) -> void:
	RpcClient.call_rpc("friend.remove", {"targetId": target_id}, func(result, err):
		if err: return
		list.erase(int(target_id))
		friend_updated.emit(-1)
	)

func _on_event(method: String, params: Dictionary) -> void:
	match method:
		"friend.added":
			var uid := int(params["userId"])
			params["userId"] = uid
			if not bool(params.get("isOnline", false)):
				params["phase"] = "offline"
			elif not params.has("phase"):
				params["phase"] = str(params.get("status", "offline"))
			RpcModules.user_store.set_user(uid, params)
			list[uid] = params
			friend_updated.emit(-1)
		"friend.removed":
			var uid := int(params["userId"])
			list.erase(uid)
			RpcModules.user_store.update_user(uid, {"phase": "offline", "status": "offline"})
			friend_removed.emit(uid)
			friend_updated.emit(-1)
