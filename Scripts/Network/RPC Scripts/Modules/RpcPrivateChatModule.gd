class_name RpcPrivateChatModule
extends RefCounted

signal message_received(from_id: int, data: Dictionary)
signal message_pushed(from_id: int, data: Dictionary)
signal history_loaded(has_more: bool)

var _limit    : int  = 100
var _offset   : int  = 0
var _has_more : bool = false
var _with_id  : int  = -1

func _init() -> void:
	RpcClient.event_received.connect(_on_event)

func set_limit(limit: int) -> void:
	_limit = limit

func get_history(with_id: int, reset: bool = true) -> void:
	_with_id = with_id
	if reset:
		_offset = 0
	RpcClient.call_rpc("chat.getPrivate", {
		"withId": with_id,
		"limit":  _limit,
		"offset": _offset
	}, func(result, err):
		if err: return
		_has_more = result.get("hasMore", false)
		for msg in result["messages"]:
			message_received.emit(int(msg.get("fromId", 0)), msg)
		history_loaded.emit(_has_more)
	)

func load_more() -> bool:
	if not _has_more or _with_id == -1:
		return false
	_offset += _limit
	get_history(_with_id, false)
	return true

func has_more() -> bool:
	return _has_more

func send(to_id: int, content: String) -> void:
	RpcClient.call_rpc("chat.sendPrivate", {
		"toId":    to_id,
		"content": content
	})

func _on_event(method: String, params: Dictionary) -> void:
	if method == "chat.privateMessage":
		message_received.emit(int(params.get("fromId", 0)), params)
		message_pushed.emit(int(params.get("fromId", 0)), params)