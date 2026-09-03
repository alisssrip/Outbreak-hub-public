extends Node

signal connected
signal disconnected
signal event_received(method: String, params: Dictionary)

var _socket   := WebSocketPeer.new()
var _pending  : Dictionary = {}
var _next_id  := 1
var _was_open := false
var _token : String = ""

func connect_to_server(token: String) -> void:
	_token = token
	var ws_url := Network_Handler.get_outbreak_backend_ws() + "/bho?token=%s" % token
	if OS.is_debug_build():
		Log.d("ws connecting: ", Network_Handler.get_outbreak_backend_ws())
	_socket.connect_to_url(ws_url)

func call_rpc(method: String, params: Dictionary, callback := Callable()) -> void:
	var id := _next_id
	_next_id += 1
	if callback.is_valid():
		_pending[id] = callback
	_socket.send_text(JSON.stringify({
		"jsonrpc": "2.0",
		"method":  method,
		"params":  params,
		"id":      id
	}))

func _process(_delta: float) -> void:
	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _was_open:
				_was_open = true
				connected.emit()
			while _socket.get_available_packet_count() > 0:
				_handle_packet(_socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSING:
			while _socket.get_available_packet_count() > 0:
				_handle_packet(_socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			while _socket.get_available_packet_count() > 0:
				_handle_packet(_socket.get_packet().get_string_from_utf8())
			if _was_open:
				_was_open = false
				disconnected.emit()

func _handle_packet(raw: String) -> void:
	var msg = JSON.parse_string(raw)
	if not msg is Dictionary: return

	if msg.has("id"):
		var id = int(msg["id"])
		if _pending.has(id):
			var cb: Callable = _pending[id]
			_pending.erase(id)
			cb.call(msg.get("result"), msg.get("error"))
			return

	if msg.has("method"):
		event_received.emit(msg["method"], msg.get("params", {}))

func is_connected_to_server() -> bool:
	return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN
