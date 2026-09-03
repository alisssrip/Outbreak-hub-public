class_name RpcLauncherModule
extends RefCounted

const VERSION := "0.0.85"
var VERSION_ENDPOINT := Network_Handler.get_outbreak_backend_api() + "/api/Launcher/version"

signal update_available(info: Dictionary)

func _init() -> void:
	RpcClient.event_received.connect(_on_event)

func _on_event(method: String, params: Dictionary) -> void:
	if method != "launcher.updateAvailable": return
	if not is_newer(str(params.get("version", "")), VERSION): return
	update_available.emit(params)

func check_version(callback: Callable) -> void:
	var req := HTTPRequest.new()
	RpcModules.add_child(req)
	req.request_completed.connect(func(result, code, headers, body):
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			callback.call(null)
			return
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json == null or not json.has("version"):
			callback.call(null)
			return
		if is_newer(str(json["version"]), VERSION):
			callback.call(json)
		else:
			callback.call(null)
	)
	req.request(VERSION_ENDPOINT)

func is_newer(remote: String, local: String) -> bool:
	var r := remote.split(".")
	var l := local.split(".")
	for i in range(max(r.size(), l.size())):
		var rv := int(r[i]) if i < r.size() else 0
		var lv := int(l[i]) if i < l.size() else 0
		if rv > lv: return true
		if rv < lv: return false
	return false
