class_name PCSX2_Pine
extends RefCounted

signal infection_read(value: float)
signal frames_read(frames: int)
signal character_read(character: int)
signal connection_changed(connected: bool)
signal state_read(state: int)
signal hits_read(total: int)
signal progress_read(raw: int)
signal shots_read(total: int)
signal survivors_read(total: int)
signal points_read(total: int)
signal config_read(character: int, scenario: int, difficulty: int, friendly_fire: int)

const TCP_HOST := "127.0.0.1"
const TCP_PORT := 28011
const POLL_MS := 500
const CONNECT_TIMEOUT_MS := 2000

const ADDR_S2 := 0x00477971
const ADDR_ALIVE := 0x00477975

const STATE_UNKNOWN := 0
const STATE_ALIVE := 1
const STATE_HIT := 2
const STATE_DOWNED := 3
const STATE_DEAD := 4

const ADDR_DIFFICULTY := 0x0060292A
const ADDR_SCENARIO := 0x0062E750
const ADDR_FRIENDLY_FIRE := 0x00603DD2

const ADDR_PROGRESS := 0x0090D278
const ADDR_SHOTS := 0x0038965C
const ADDR_SURVIVORS := 0x00389696
const ADDR_POINTS := 0x00389654
const PROGRESS_ENABLED := true

const CMD_READ8 := 0x00
const CMD_READ16 := 0x01
const CMD_READ32 := 0x02
const CMD_READ64 := 0x03
const CMD_VERSION := 0x0F

const ADDR_INFECTION := 0x01FC96B0
const ADDR_FRAMES := 0x0048BF78
const ADDR_CHARACTER := 0x0062E234

var ctx
var _thread: Thread
var _running := false
var _connected := false
var _want_config := false

var _hits := 0
var _prev_hit_bit := 0
var _cfg_last := []
var _cfg_locked := false

func init(hndlr) -> void:
	ctx = hndlr

func start() -> void:
	if _running:
		Log.d("[pine] restarting, previous poll still alive")
		stop()
	_running = true
	_want_config = true
	_hits = 0
	_prev_hit_bit = 0
	_cfg_last = []
	_cfg_locked = false
	_thread = Thread.new()
	_thread.start(_loop)

func lock_config() -> void:
	_cfg_locked = true

func stop() -> void:
	_running = false
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null
	_connected = false

func _loop() -> void:
	while _running:
		var st = _read_state_once()
		var inf = _read_infection_once()
		var fr = _read_frames_once()
		var sh = _read_shots_once()
		var sv = _read_survivors_once()
		var pt = _read_points_once()
		if not _cfg_locked:
			var cfg = _read_config_once()
			if cfg != null:
				_apply_cfg_latch(cfg)
		if _cfg_last.size() == 4:
			call_deferred("emit_signal", "config_read", _cfg_last[0], _cfg_last[1], _cfg_last[2], _cfg_last[3])
		if PROGRESS_ENABLED:
			var pg = _read_progress_once()
			if pg != null:
				call_deferred("emit_signal", "progress_read", pg)
		if st != null: 
			call_deferred("emit_signal", "state_read", st)
			call_deferred("emit_signal", "hits_read", _hits)
		if inf != null:
			call_deferred("emit_signal", "infection_read", inf)
		if fr != null:
			call_deferred("emit_signal", "frames_read", fr)
		if sh != null:
			call_deferred("emit_signal", "shots_read", sh)
		if sv != null:
			call_deferred("emit_signal", "survivors_read", sv)
		if pt != null:
			call_deferred("emit_signal", "points_read", pt)
		OS.delay_msec(POLL_MS)

func _apply_cfg_latch(cfg) -> void:
	var ch : int = cfg[0]
	var is_clear : bool = (ch == 0x00 or ch == 0xFF)
	var prev_ch : int = _cfg_last[0] if _cfg_last.size() == 4 else 0
	var have_valid : bool = _cfg_last.size() == 4 and prev_ch != 0x00 and prev_ch != 0xFF
	if is_clear and have_valid:
		return
	_cfg_last = cfg

func _read_config_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var ch = _request(peer, CMD_READ8, ADDR_CHARACTER, 1)
	var sc = _request(peer, CMD_READ8, ADDR_SCENARIO, 1)
	var df = _request(peer, CMD_READ8, ADDR_DIFFICULTY, 1)
	var ff = _request(peer, CMD_READ8, ADDR_FRIENDLY_FIRE, 1)
	_disconnect(peer)
	if ch == null or sc == null or df == null or ff == null:
		return null
	return [ch[0], sc[0], df[0], ff[0]]

func _read_progress_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var d = _request(peer, CMD_READ8, ADDR_PROGRESS, 1)
	_disconnect(peer)
	if d == null:
		return null
	return d[0]

func _read_infection_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var s := ""
	for i in range(6):
		var d = _request(peer, CMD_READ8, ADDR_INFECTION + i, 1)
		if d == null:
			break
		var b : int = d[0]
		if b == 0:
			break
		s += char(b)
	_disconnect(peer)
	if s.is_empty() or not s.is_valid_int():
		return 0.0
	return s.to_int() / 100.0

func _read_state_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var d2 = _request(peer, CMD_READ8, ADDR_S2, 1)
	var da = _request(peer, CMD_READ8, ADDR_ALIVE, 1)
	_disconnect(peer)
	if d2 == null or da == null:
		return null
	var s2 : int = d2[0]
	var s5 : int = da[0]
	var hit_bit := 1 if (s2 & 0x02) else 0
	var blocked := (s2 & 0x01) or (s2 & 0x04)
	if hit_bit == 1 and _prev_hit_bit == 0 and not blocked:
		_hits += 1
	_prev_hit_bit = hit_bit
	return _decode_state(s2, s5)

func _decode_state(s2: int, s5: int) -> int:
	if s2 & 0x01:
		return STATE_DEAD
	if s2 & 0x04:
		return STATE_DOWNED
	if s5 & 0x01:
		return STATE_ALIVE
	if s2 & 0x02:
		return STATE_HIT
	return STATE_UNKNOWN

func _read_frames_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var d = _request(peer, CMD_READ32, ADDR_FRAMES, 4)
	_disconnect(peer)
	if d == null:
		return null
	return d.decode_u32(0)

func _read_shots_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var d = _request(peer, CMD_READ16, ADDR_SHOTS, 2)
	_disconnect(peer)
	if d == null:
		return null
	return d.decode_u16(0)

func _read_survivors_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var d = _request(peer, CMD_READ8, ADDR_SURVIVORS, 1)
	_disconnect(peer)
	if d == null:
		return null
	return d[0]

func _read_points_once():
	var peer := _connect()
	if peer == null:
		_set_connected(false)
		return null
	_set_connected(true)
	_handshake(peer)
	var d = _request(peer, CMD_READ32, ADDR_POINTS, 4)
	_disconnect(peer)
	if d == null:
		return null
	return d.decode_u32(0)

func _read_once_u8(addr: int):
	var peer := _connect()
	if peer == null:
		return null
	_handshake(peer)
	var d = _request(peer, CMD_READ8, addr, 1)
	_disconnect(peer)
	if d == null:
		return null
	return d[0]

func _set_connected(state: bool) -> void:
	if state == _connected:
		return
	_connected = state
	call_deferred("emit_signal", "connection_changed", state)

func _connect() -> StreamPeer:
	if OS.get_name() == "Windows":
		return _connect_tcp()
	return _connect_uds()

func _connect_tcp() -> StreamPeer:
	var tcp := StreamPeerTCP.new()
	if tcp.connect_to_host(TCP_HOST, TCP_PORT) != OK:
		return null
	var waited := 0
	while waited < CONNECT_TIMEOUT_MS:
		tcp.poll()
		var st := tcp.get_status()
		if st == StreamPeerTCP.STATUS_CONNECTED:
			return tcp
		if st == StreamPeerTCP.STATUS_ERROR:
			return null
		OS.delay_msec(10)
		waited += 10
	return null

func _connect_uds() -> StreamPeer:
	for path in _uds_paths():
		var uds = ClassDB.instantiate("StreamPeerUDS")
		if uds == null:
			return null
		if uds.connect_to_host(path) != OK:
			continue
		var waited := 0
		while waited < CONNECT_TIMEOUT_MS:
			uds.poll()
			var st = uds.get_status()
			if st == StreamPeerTCP.STATUS_CONNECTED:
				return uds
			if st == StreamPeerTCP.STATUS_ERROR:
				break
			OS.delay_msec(10)
			waited += 10
	return null

func _uds_paths() -> Array:
	var paths := []
	var xdg := OS.get_environment("XDG_RUNTIME_DIR")
	if xdg != "":
		paths.append(xdg + "/pcsx2.sock")
	paths.append("/tmp/pcsx2.sock")
	return paths

func _read_exact(peer: StreamPeer, n: int):
	var buf := PackedByteArray()
	var waited := 0
	while buf.size() < n:
		var need := n - buf.size()
		var res := peer.get_data(need)
		if res[0] != OK:
			return null
		var chunk: PackedByteArray = res[1]
		if chunk.size() == 0:
			OS.delay_msec(1)
			waited += 1
			if waited > 500:
				return null
			continue
		buf.append_array(chunk)
	return buf

func _handshake(peer: StreamPeer) -> void:
	var h := PackedByteArray([0x05, 0x00, 0x00, 0x00, CMD_VERSION])
	if peer.put_data(h) != OK:
		return
	var len_buf = _read_exact(peer, 4)
	if len_buf == null:
		return
	var total : int = len_buf.decode_u32(0)
	if total > 4:
		_read_exact(peer, total - 4)

func _disconnect(peer: StreamPeer) -> void:
	if peer is StreamPeerTCP:
		(peer as StreamPeerTCP).disconnect_from_host()
	else:
		peer.call("disconnect_from_host")

func _request(peer: StreamPeer, cmd: int, addr: int, reply_data_len: int):
	var pkt := PackedByteArray()
	pkt.resize(9)
	pkt.encode_u32(0, 9)
	pkt[4] = cmd
	pkt.encode_u32(5, addr)
	if peer.put_data(pkt) != OK:
		return null
	var len_buf = _read_exact(peer, 4)
	if len_buf == null:
		return null
	var total : int = len_buf.decode_u32(0)
	if total < 5:
		return null
	var body = _read_exact(peer, total - 4)
	if body == null:
		return null
	if body.size() < 1 + reply_data_len:
		return null
	if body[0] != 0:
		return null
	return body.slice(1, 1 + reply_data_len)