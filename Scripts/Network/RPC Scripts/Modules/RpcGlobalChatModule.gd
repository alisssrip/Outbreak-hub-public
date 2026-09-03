class_name RpcGlobalChatModule
extends RefCounted

signal global_message_received(data: Dictionary)
signal global_message_pushed(data: Dictionary)
signal history_loaded(has_more: bool)

var _limit        : int  = 100
var _offset       : int  = 0
var _has_more     : bool = false

func _init() -> void:
	RpcClient.event_received.connect(_on_event)

func set_limit(limit: int) -> void:
	_limit = limit

func get_history(reset: bool = true) -> void:
	if reset:
		_offset = 0
	RpcClient.call_rpc("chat.getGlobal", {"limit": _limit, "offset": _offset}, func(result, err):
		if err: return
		_has_more = result.get("hasMore", false)
		for msg in result["messages"]:
			global_message_received.emit(msg)
		history_loaded.emit(_has_more)
	)

func load_more() -> bool:
	if not _has_more:
		return false
	_offset += _limit
	get_history(false)
	return true

func has_more() -> bool:
	return _has_more

func send_global(content: String) -> void:
	RpcClient.call_rpc("chat.sendGlobal", {"content": content})

func _on_event(method: String, params: Dictionary) -> void:
	if method == "chat.globalMessage":
		global_message_received.emit(params)
		global_message_pushed.emit(params)