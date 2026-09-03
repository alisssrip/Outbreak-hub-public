class_name RpcUserSearchModule
extends RefCounted

signal search_started()
signal search_completed(user_ids: Array)
signal search_failed()

var _in_flight : bool = false

func search(query: String) -> void:
	var q := query.strip_edges()
	if q.is_empty():
		search_completed.emit([])
		return
	if _in_flight: return
	_in_flight = true
	search_started.emit()
	RpcClient.call_rpc("user.search", {"query": q}, func(result, err):
		_in_flight = false
		if err:
			search_failed.emit()
			return
		var users : Array = result.get("users", [])
		var ids : Array = []
		for u in users:
			var uid := int(u["userId"])
			RpcModules.user_store.set_user(uid, u)
			ids.append(uid)
		search_completed.emit(ids)
)