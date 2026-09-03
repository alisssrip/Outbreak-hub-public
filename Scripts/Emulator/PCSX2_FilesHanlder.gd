class_name PCSX2_FilesHanlder
extends RefCounted

const PCSX2_LINUX_URL := "https://github.com/alisssrip/outbreak-utilities/releases/download/pcsx2/PCSX2_LINUX.zip"
const PCSX2_WIN_URL := "https://github.com/alisssrip/outbreak-utilities/releases/download/pcsx2/PCSX2_WIN.zip"

signal install_finished()
signal install_failed(reason: String)

var ctx
var _http: HTTPRequest

func init(hndlr) -> void:
	ctx = hndlr

func _base_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://")
	return OS.get_executable_path().get_base_dir() + "/"

func _exe_name() -> String:
	return "pcsx2-qt.exe" if OS.get_name() == "Windows" else "pcsx2-qt"

func _exe_path() -> String:
	return _base_path().path_join("PCSX2").path_join("usr").path_join("bin").path_join(_exe_name())

func is_installed() -> bool:
	return FileAccess.file_exists(_exe_path())

func verify_integrity() -> bool:
	var path := _exe_path()
	if not FileAccess.file_exists(path):
		Log.d("[INTEGRITY] pcsx2 missing: %s" % path)
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var size := f.get_length()
	f.close()
	if size <= 0:
		Log.d("[INTEGRITY] pcsx2 empty: %s" % path)
		return false
	return true

func install() -> void:
	_install_flow()

func _install_flow() -> void:
	var root := _base_path()
	var pcsx2_dir := root.path_join("PCSX2")
	var zip_path := root.path_join("pcsx2_tmp.zip")
	var url := PCSX2_WIN_URL if OS.get_name() == "Windows" else PCSX2_LINUX_URL

	_remove_dir_recursive(pcsx2_dir)

	var cancel = func():
		install_failed.emit("pcsx2_download")
		return
	Popups_Controller.instance.show_progress(tr("INSTALL_DOWNLOADING_PCSX2"), cancel)
	if not await _download(url, zip_path):
		install_failed.emit("pcsx2_download")
		return

	Popups_Controller.instance.progress_scene.close_popup()
	Popups_Controller.instance.show_spinner(tr("INSTALL_UNZIPPING_PCSX2"))
	if not await _unzip(zip_path, root):
		install_failed.emit("pcsx2_unzip")
		return
	if OS.get_name() != "Windows":
		_chmod_exe()
	Popups_Controller.instance.spinner_scene.close_popup()

	DirAccess.remove_absolute(zip_path)
	install_finished.emit()

func _download(url: String, target: String) -> bool:
	_http = HTTPRequest.new()
	ctx.add_child(_http)
	_http.download_file = target
	var done := [false, false]
	_http.request_completed.connect(func(result, code, headers, body):
		done[0] = true
		done[1] = (result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 400)
	)
	if _http.request(url) != OK:
		_http.queue_free()
		return false
	while not done[0]:
		await ctx.get_tree().process_frame
		_update_progress()
	_http.queue_free()
	_http = null
	if not done[1]:
		return false
	var expected := await _fetch_hash(url + ".sha256")
	if expected == "":
		Log.d("[INTEGRITY] could not fetch hash for %s" % url)
		return false
	if not _verify_hash(target, expected):
		Log.d("[INTEGRITY] hash mismatch for %s" % target)
		return false
	return true

func _update_progress() -> void:
	if _http and _http.get_http_client_status() == HTTPClient.STATUS_BODY:
		var total := _http.get_body_size()
		var got := _http.get_downloaded_bytes()
		if total > 0 and Popups_Controller.instance.progress_scene:
			Popups_Controller.instance.progress_scene.set_progress(float(got) / float(total) * 100.0)

func _fetch_hash(hash_url: String) -> String:
	var req := HTTPRequest.new()
	ctx.add_child(req)
	var result := [""]
	var done := [false]
	req.request_completed.connect(func(r, code, headers, body):
		if r == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 400:
			result[0] = body.get_string_from_utf8().strip_edges().split(" ")[0].to_lower()
		done[0] = true
	)
	if req.request(hash_url) != OK:
		req.queue_free()
		return ""
	while not done[0]:
		await ctx.get_tree().process_frame
	req.queue_free()
	return result[0]

func _verify_hash(path: String, expected: String) -> bool:
	if expected.is_empty():
		return false
	var c := HashingContext.new()
	c.start(HashingContext.HASH_SHA256)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	while not f.eof_reached():
		var chunk := f.get_buffer(65536)
		if chunk.size() > 0:
			c.update(chunk)
	f.close()
	var digest := c.finish()
	var hex := ""
	for b in digest:
		hex += "%02x" % b
	return hex == expected

func _unzip(zip_path: String, dest: String) -> bool:
	DirAccess.make_dir_recursive_absolute(dest)
	var pid: int
	if OS.get_name() == "Windows":
		pid = OS.create_process("tar", ["-xf", zip_path, "-C", dest])
	else:
		pid = OS.create_process("unzip", ["-o", zip_path, "-d", dest])
	if pid == -1:
		return await _unzip_native(zip_path, dest)
	while OS.is_process_running(pid):
		await ctx.get_tree().create_timer(0.2).timeout
	return true

func _unzip_native(zip_path: String, dest: String) -> bool:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return false
	for fname in reader.get_files():
		var out_path := dest.path_join(fname)
		if fname.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(out_path)
			continue
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		var data := reader.read_file(fname)
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f:
			f.store_buffer(data)
			f.close()
		await ctx.get_tree().process_frame
	reader.close()
	return true

func _chmod_exe() -> void:
	OS.execute("chmod", ["+x", _exe_path()])

func _remove_dir_recursive(path: String) -> void:
	var da := DirAccess.open(path)
	if da == null:
		return
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		if name != "." and name != "..":
			var full := path.path_join(name)
			if da.current_is_dir():
				_remove_dir_recursive(full)
			else:
				DirAccess.remove_absolute(full)
		name = da.get_next()
	da.list_dir_end()
	DirAccess.remove_absolute(path)