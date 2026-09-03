class_name DiscordTransportUDS
extends RefCounted

const CONNECT_TIMEOUT_MS := 1000
const READ_TIMEOUT_MS := 3000
const SOCKET_COUNT := 10

var _peer

func open() -> bool:
	for path in _paths():
		var uds = ClassDB.instantiate("StreamPeerUDS")
		if uds == null:
			return false
		if uds.connect_to_host(path) != OK:
			continue
		var waited := 0
		while waited < CONNECT_TIMEOUT_MS:
			uds.poll()
			var st = uds.get_status()
			if st == StreamPeerSocket.STATUS_CONNECTED:
				_peer = uds
				return true
			if st == StreamPeerSocket.STATUS_ERROR:
				break
			OS.delay_msec(10)
			waited += 10
	return false

func send(op: int, payload: PackedByteArray) -> bool:
	if _peer == null:
		return false
	var pkt := PackedByteArray()
	pkt.resize(8)
	pkt.encode_u32(0, op)
	pkt.encode_u32(4, payload.size())
	pkt.append_array(payload)
	return _peer.put_data(pkt) == OK

func recv():
	var head = _read_exact(8)
	if head == null:
		return null
	var op : int = head.decode_u32(0)
	var length : int = head.decode_u32(4)
	var body := PackedByteArray()
	if length > 0:
		body = _read_exact(length)
		if body == null:
			return null
	return {"op": op, "data": body}

func close() -> void:
	if _peer != null:
		_peer.call("disconnect_from_host")
		_peer = null

func _read_exact(n: int):
	if _peer == null:
		return null
	var buf := PackedByteArray()
	var waited := 0
	while buf.size() < n:
		_peer.poll()
		if _peer.get_status() != StreamPeerSocket.STATUS_CONNECTED:
			return null
		var avail : int = _peer.get_available_bytes()
		if avail <= 0:
			OS.delay_msec(10)
			waited += 10
			if waited > READ_TIMEOUT_MS:
				return null
			continue
		var res = _peer.get_data(mini(avail, n - buf.size()))
		if res[0] != OK:
			return null
		buf.append_array(res[1])
	return buf

func _paths() -> Array:
	var out := []
	for base in _bases():
		var dir := DirAccess.open(base)
		if dir == null:
			continue
		for i in range(SOCKET_COUNT):
			var entry := "discord-ipc-%d" % i
			if dir.file_exists(entry):
				out.append(base.path_join(entry))
	return out

func _bases() -> Array:
	var bases := []
	var xdg := OS.get_environment("XDG_RUNTIME_DIR")
	if xdg != "":
		bases.append(xdg)
		bases.append(xdg.path_join("app/com.discordapp.Discord"))
		bases.append(xdg.path_join("snap.discord"))
	var tmp := OS.get_environment("TMPDIR")
	if tmp != "":
		bases.append(tmp)
	bases.append("/tmp")
	return bases
