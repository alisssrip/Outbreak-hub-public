extends Node

const PCK_TMP := "user://update.pck.tmp"
const PCK_TARGET_NAME := "OUTBREAK.pck"

signal progress(percent: float)
signal finished()
signal failed(reason: String)

var _info : Dictionary = {}
var _http : HTTPRequest
var _remote_hash := ""

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_pck_downloaded)

func start_download(info: Dictionary) -> void:
	_info = info
	var hash_url := str(info.get("hashUrl", ""))
	if hash_url.is_empty():
		_remote_hash = ""
		_download_pck()
		return
	var hreq := HTTPRequest.new()
	add_child(hreq)
	hreq.request_completed.connect(func(result, code, headers, body):
		hreq.queue_free()
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			_remote_hash = body.get_string_from_utf8().strip_edges().split(" ")[0].to_lower()
		else:
			_remote_hash = ""
		_download_pck()
	)
	hreq.request(hash_url)

func _download_pck() -> void:
	var pck_url := str(_info.get("pckUrl", ""))
	if pck_url.is_empty():
		failed.emit("no_pck_url")
		return
	_http.download_file = PCK_TMP
	if _http.request(pck_url) != OK:
		failed.emit("request_failed")
		return
	set_process(true)

func _process(_delta: float) -> void:
	if _http.get_http_client_status() == HTTPClient.STATUS_BODY:
		var total := _http.get_body_size()
		var got := _http.get_downloaded_bytes()
		if total > 0:
			progress.emit(float(got) / float(total) * 100.0)

func _on_pck_downloaded(result, code, headers, body) -> void:
	set_process(false)
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		failed.emit("download_failed")
		return
	if not _verify_hash(PCK_TMP, _remote_hash):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PCK_TMP))
		failed.emit("hash_mismatch")
		return
	if not _apply_pck():
		failed.emit("apply_failed")
		return
	progress.emit(100.0)
	finished.emit()

func cancel_download() -> void:
	set_process(false)
    
	if _http and is_instance_valid(_http):
		if _http.request_completed.is_connected(_on_pck_downloaded):
			_http.request_completed.disconnect(_on_pck_downloaded)
        
		_http.queue_free()
		_http = null
    
	var tmp_abs := ProjectSettings.globalize_path(PCK_TMP)
	if FileAccess.file_exists(tmp_abs):
		DirAccess.remove_absolute(tmp_abs)
    
	Log.d("Descarga abortada y nodo HTTP liberado.")
	LauncherController.instance._on_close_requested()
	failed.emit("user_cancelled")
    
func restart() -> void:
	OS.create_process(OS.get_executable_path(), [])
	get_tree().quit()

func _verify_hash(path: String, expected: String) -> bool:
	if expected.is_empty(): return true
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return false
	while not f.eof_reached():
		var chunk := f.get_buffer(65536)
		if chunk.size() > 0:
			ctx.update(chunk)
	f.close()
	var digest := ctx.finish()
	var hex := ""
	for b in digest:
		hex += "%02x" % b
	return hex == expected

func _apply_pck() -> bool:
	var exe_dir := OS.get_executable_path().get_base_dir()
	var target := exe_dir.path_join(PCK_TARGET_NAME)
	var tmp_abs := ProjectSettings.globalize_path(PCK_TMP)
	var da := DirAccess.open(exe_dir)
	if da == null: return false
	if FileAccess.file_exists(target):
		da.remove(target)
	if da.copy(tmp_abs, target) != OK: return false
	DirAccess.remove_absolute(tmp_abs)
	return true