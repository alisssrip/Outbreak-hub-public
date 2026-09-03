extends Node

var paths := PCSX2_Paths.new()
var ini := PCSX2_IniHelper.new()
var graphics := PCSX2_Graphics.new()
var controls := PCSX2_Controls.new()
var achievements := PCSX2_Achievements.new()
var anticheat := PCSX2_AntiCheat.new()
var launch := PCSX2_Launch.new()
var pine := PCSX2_Pine.new()
var files := PCSX2_FilesHanlder.new()

var _seen_alive := false
signal emulator_opened()
signal emulator_closed()

var _monitor_timer: Timer
var _was_running := false

const VALID_OUTBREAK_IDS := ["SLPM-65428"]
const SCPH10000_MD5 := "acf4730ceb38ac9d8c7d8e21f2614600"

func _ready() -> void:
	paths.init(self)
	ini.init(self)
	graphics.init(self)
	controls.init(self)
	achievements.init(self)
	anticheat.init(self)
	launch.init(self)
	pine.init(self)
	files.init(self)

	_monitor_timer = Timer.new()
	_monitor_timer.wait_time = 1.0
	_monitor_timer.timeout.connect(_monitor_process)
	add_child(_monitor_timer)

func start_monitoring() -> void:
	_seen_alive = false
	emulator_opened.emit()
	_monitor_timer.start()


func _monitor_process() -> void:
	if launch.is_running():
		_seen_alive = true
		return
	if not _seen_alive:
		return
	_monitor_timer.stop()
	emulator_closed.emit()

func stop_monitoring() -> void:
	_seen_alive = false
	_monitor_timer.stop()

func is_valid_outbreak(path: String) -> bool:
	var id = read_iso_serial(path)
	if not VALID_OUTBREAK_IDS.has(id):
		print("rejected iso ", id)
		return false
	print("iso serial ", id)
	return true


func read_iso_serial(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("iso open failed")
		return ""
	f.seek(16 * 2048)
	var pvd := f.get_buffer(2048)
	if pvd.slice(1, 6).get_string_from_ascii() != "CD001":
		print("not iso9660")
		return ""
	var root_lba := pvd.decode_u32(156 + 2)
	var root_size := pvd.decode_u32(156 + 10)
	f.seek(root_lba * 2048)
	var dir := f.get_buffer(root_size)
	var p := 0
	while p < dir.size():
		var rec_len := dir[p]
		if rec_len == 0:
			p = (p / 2048 + 1) * 2048
			continue
		var name_len := dir[p + 32]
		var entry := dir.slice(p + 33, p + 33 + name_len).get_string_from_ascii()
		if entry.begins_with("SYSTEM.CNF"):
			var lba := dir.decode_u32(p + 2)
			var sz := dir.decode_u32(p + 10)
			f.seek(lba * 2048)
			return _parse_serial(f.get_buffer(sz).get_string_from_ascii())
		p += rec_len
	return ""

func _parse_serial(cnf: String) -> String:
	for line in cnf.split("\n"):
		if line.begins_with("BOOT2"):
			var idx := line.find("\\")
			if idx == -1:
				return ""
			var token := line.substr(idx + 1).strip_edges().split(";")[0]
			return token.replace(".", "").replace("_", "-")
	return ""

func is_bios_valid(path: String) -> bool:
	return _bios_check(path)

func _bios_check(path: String) -> bool:
	var md5 := FileAccess.get_md5(path)
	if md5 != SCPH10000_MD5:
		print("bios rejected ", md5)
		return false
	print("bios md5 ", md5)
	return true
