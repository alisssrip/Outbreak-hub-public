class_name RpcFriendRequestsModule
extends RefCounted

signal request_added(from_id: int)
signal request_removed(from_id: int)
signal requests_loaded(from_ids: Array)

var pending : Dictionary = {}

func _init() -> void:
	RpcClient.event_received.connect(_on_event)

func load_pending() -> void:
	RpcClient.call_rpc("friend.getPending", {}, func(result, err):
		if err: return
		pending.clear()
		var ids : Array = []
		for r in result["requests"]:
			var uid := int(r["userId"])
			RpcModules.user_store.set_user(uid, r)
			pending[uid] = true
			ids.append(uid)
		requests_loaded.emit(ids)
	)

func accept(from_id: int) -> void:
	RpcClient.call_rpc("friend.accept", {"fromId": from_id}, func(result, err):
		if err: return
		pending.erase(from_id)
		request_removed.emit(from_id)
	)

func decline(from_id: int) -> void:
	RpcClient.call_rpc("friend.decline", {"fromId": from_id}, func(result, err):
		if err: return
		pending.erase(from_id)
		request_removed.emit(from_id)
	)

func _on_event(method: String, params: Dictionary) -> void:
	if method == "friend.requestReceived":
		var uid := int(params["userId"])
		RpcModules.user_store.set_user(uid, params)
		pending[uid] = true
		request_added.emit(uid)