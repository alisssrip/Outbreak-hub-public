class_name DiscordIPC
extends RefCounted

const OP_HANDSHAKE := 0
const OP_FRAME := 1

const TICK_MS := 200
const RECONNECT_MS := 15000

var _thread: Thread
var _mutex := Mutex.new()
var _running := false
var _app_id := ""
var _activity: Dictionary = {}
var _activity_json := ""
var _dirty := false
var _nonce := 0
var _transport
var _fail_logged := false

func start(app_id: String) -> void:
	if _running:
		return
	_app_id = app_id
	_running = true
	_thread = Thread.new()
	_thread.start(_loop)

func stop() -> void:
	if not _running:
		return
	_mutex.lock()
	_running = false
	var t = _transport
	_mutex.unlock()
	if t != null:
		t.close()
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null

func set_activity(activity: Dictionary) -> void:
	var encoded := JSON.stringify(activity)
	_mutex.lock()
	if encoded != _activity_json:
		_activity_json = encoded
		_activity = activity
		_dirty = true
	_mutex.unlock()

func _loop() -> void:
	var next_try := 0
	while _is_running():
		var t = _current()
		if t == null:
			if Time.get_ticks_msec() < next_try:
				OS.delay_msec(TICK_MS)
				continue
			if not _connect():
				next_try = Time.get_ticks_msec() + RECONNECT_MS
				OS.delay_msec(TICK_MS)
			continue
		if _take_dirty() and not _push(t):
			_log("[discord] connection lost")
			_drop()
			next_try = Time.get_ticks_msec() + RECONNECT_MS
			continue
		OS.delay_msec(TICK_MS)
	_drop()

func _connect() -> bool:
	var t = DiscordTransportPipe.new() if OS.get_name() == "Windows" else DiscordTransportUDS.new()
	if not t.open():
		t.close()
		_log_fail("[discord] no ipc socket")
		return false
	if not _handshake(t):
		t.close()
		_log_fail("[discord] handshake failed")
		return false
	_mutex.lock()
	_transport = t
	_dirty = true
	_mutex.unlock()
	_fail_logged = false
	_log("[discord] connected")
	return true

func _handshake(t) -> bool:
	var payload := JSON.stringify({"v": 1, "client_id": _app_id})
	if not t.send(OP_HANDSHAKE, payload.to_utf8_buffer()):
		return false
	var frame = t.recv()
	return frame != null and int(frame["op"]) == OP_FRAME

func _push(t) -> bool:
	_mutex.lock()
	var act : Dictionary = _activity.duplicate(true)
	_mutex.unlock()
	_nonce += 1
	var cmd := {
		"cmd": "SET_ACTIVITY",
		"nonce": str(_nonce),
		"args": {"pid": OS.get_process_id(), "activity": null if act.is_empty() else act}
	}
	if not t.send(OP_FRAME, JSON.stringify(cmd).to_utf8_buffer()):
		return false
	return t.recv() != null

func _drop() -> void:
	_mutex.lock()
	var t = _transport
	_transport = null
	_mutex.unlock()
	if t != null:
		t.close()

func _current():
	_mutex.lock()
	var t = _transport
	_mutex.unlock()
	return t

func _is_running() -> bool:
	_mutex.lock()
	var r := _running
	_mutex.unlock()
	return r

func _take_dirty() -> bool:
	_mutex.lock()
	var d := _dirty
	_dirty = false
	_mutex.unlock()
	return d

func _log(msg: String) -> void:
	Log.call_deferred("d", msg)

func _log_fail(msg: String) -> void:
	if _fail_logged:
		return
	_fail_logged = true
	_log(msg)
