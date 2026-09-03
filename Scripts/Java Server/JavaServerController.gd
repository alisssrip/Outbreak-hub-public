class_name JavaServerController
extends Node

signal install_progress(percent: float)
signal install_finished()
signal install_failed(reason: String)

var SERVER_STATUS = false
var server_pid: int = -1
var current_sessid: String = ""

const HEARTBEAT_INTERVAL = 5.0
const LAUNCH_CHECK_DELAY = 1.5
const KILL_TIMEOUT_MS = 5000
const KILL_POLL_MS = 50

const JDK_LINUX_URL := "https://github.com/alisssrip/jkd17-outbreak-mirrors/releases/download/jdk/jdk-17.0.12.linux.zip"
const JDK_WIN_URL := "https://github.com/alisssrip/jkd17-outbreak-mirrors/releases/download/jdk/jdk-17.0.12.win.zip"
const SERVER_URL := "https://github.com/alisssrip/BHOF1-JAVA-SERVER/releases/download/1.0/Java-Server.jar"

var heartbeat_timer: Timer
var is_registered = false

var _http: HTTPRequest
var _dl_target := ""

func _base_path() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://")
	return OS.get_executable_path().get_base_dir() + "/"

func _java_exe_name() -> String:
	return "javaw.exe" if OS.get_name() == "Windows" else "java"

func _java_path() -> String:
	return _base_path().path_join("Java-Server").path_join("JRE").path_join("JDK").path_join("bin").path_join(_java_exe_name())

func _server_jar_path() -> String:
	return _base_path().path_join("Java-Server").path_join("Java-Server.jar")

func is_installed() -> bool:
	return FileAccess.file_exists(_java_path()) and FileAccess.file_exists(_server_jar_path())

func verify_integrity() -> bool:
	var jdk_dir := _base_path().path_join("Java-Server").path_join("JRE").path_join("JDK")
	var checks := [
		_java_path(),
		jdk_dir.path_join("lib"),
		_server_jar_path(),
	]
	for path in checks:
		if not _exists_nonempty(path):
			Log.d("[INTEGRITY] missing or empty: %s" % path)
			return false
	return true

func _exists_nonempty(path: String) -> bool:
	if DirAccess.dir_exists_absolute(path):
		var da := DirAccess.open(path)
		if da == null:
			return false
		da.list_dir_begin()
		var has_content := false
		var name := da.get_next()
		while name != "":
			if name != "." and name != "..":
				has_content = true
				break
			name = da.get_next()
		da.list_dir_end()
		return has_content
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			return false
		var size := f.get_length()
		f.close()
		return size > 0
	return false

func is_server_running() -> bool:
	return server_pid != -1 and OS.is_process_running(server_pid)

func refresh_status() -> bool:
	if SERVER_STATUS and not is_server_running():
		Log.d("[SERVER] process is gone, clearing status")
		_clear_server_state()
	return SERVER_STATUS

func launch_and_verify_server() -> bool:
	if is_server_running():
		Log.d("[SERVER] already running PID: %d" % server_pid)
		SERVER_STATUS = true
		return true
	_clear_server_state()
	if not verify_integrity():
		Log.d("[ERROR] Java server files missing")
		return false
	var absolute_java_path = _java_path()
	var jar_path = _server_jar_path()
	var arguments = ["-jar", jar_path]
	server_pid = OS.create_process(absolute_java_path, arguments, true)
	if server_pid == -1:
		Log.d("[ERROR] Could not launch Java process")
		SERVER_STATUS = false
		return false
	await get_tree().create_timer(LAUNCH_CHECK_DELAY).timeout
	if not OS.is_process_running(server_pid):
		Log.d("[ERROR] Java server died right after launch")
		_clear_server_state()
		return false
	Log.d("[OK] Server started PID: %d" % server_pid)
	start_heartbeat_loop()
	SERVER_STATUS = true
	return true

func kill_server() -> bool:
	if server_pid == -1:
		_clear_server_state()
		return true
	Log.d("[LAUNCHER] Killing Java server")
	var pid := server_pid
	OS.kill(pid)
	var start := Time.get_ticks_msec()
	while OS.is_process_running(pid):
		if Time.get_ticks_msec() - start > KILL_TIMEOUT_MS:
			Log.d("[ERROR] Java server still alive after kill")
			return false
		OS.delay_msec(KILL_POLL_MS)
	Log.d("[OK] Java server stopped")
	_clear_server_state()
	return true

func kill_server_async() -> bool:
	if server_pid == -1:
		_clear_server_state()
		return true
	Log.d("[LAUNCHER] Killing Java server")
	var pid := server_pid
	OS.kill(pid)
	var start := Time.get_ticks_msec()
	while OS.is_process_running(pid):
		if Time.get_ticks_msec() - start > KILL_TIMEOUT_MS:
			Log.d("[ERROR] Java server still alive after kill")
			return false
		await get_tree().create_timer(float(KILL_POLL_MS) / 1000.0).timeout
	Log.d("[OK] Java server stopped")
	_clear_server_state()
	return true

func _clear_server_state() -> void:
	server_pid = -1
	current_sessid = ""
	if is_instance_valid(heartbeat_timer):
		heartbeat_timer.queue_free()
	heartbeat_timer = null
	SERVER_STATUS = false

# ---- INSTALL ----

func install_dependencies(onComplete: Callable) -> void:
	_install_flow(onComplete)

func _install_flow(onComplete: Callable) -> void:
	var server_base := _base_path().path_join("Java-Server")
	var jre_dir := server_base.path_join("JRE")
	var jdk_dir := jre_dir.path_join("JDK")

	# Limpiar instalacion previa (corrupta o parcial)
	_remove_dir_recursive(jdk_dir)
	DirAccess.remove_absolute(_server_jar_path())
	DirAccess.make_dir_recursive_absolute(jdk_dir)

	var jdk_url := JDK_WIN_URL if OS.get_name() == "Windows" else JDK_LINUX_URL
	var jdk_zip := _base_path().path_join("jdk_tmp.zip")
	var jdk_extract := _base_path().path_join("jdk_extract_tmp")
	var jar_path := _server_jar_path()

	# 1. Descargar JDK
	Popups_Controller.instance.show_progress(tr("INSTALL_DOWNLOADING_JDK"), func(): pass)
	if not await _download(jdk_url, jdk_zip):
		install_failed.emit("jdk_download")
		return

	# 2. Descomprimir JDK (a carpeta temporal)
	Popups_Controller.instance.progress_scene.close_popup()
	Popups_Controller.instance.show_spinner(tr("INSTALL_UNZIPPING_JDK"))
	DirAccess.make_dir_recursive_absolute(jdk_extract)
	if not await _unzip(jdk_zip, jdk_extract):
		install_failed.emit("jdk_unzip")
		return

	# 3. Mover contenido de jdk-XXX/ a JRE/JDK/
	Popups_Controller.instance.spinner_scene.set_text(tr("INSTALL_MOVING_FILES"))
	if not _move_jdk_contents(jdk_extract, jdk_dir):
		install_failed.emit("jdk_move")
		return
	if OS.get_name() != "Windows":
		_chmod_java()
	Popups_Controller.instance.spinner_scene.close_popup()

	# 4. Descargar Server (jar directo, sin descomprimir)
	Popups_Controller.instance.show_progress(tr("INSTALL_DOWNLOADING_SERVER"), func(): pass)
	if not await _download(SERVER_URL, jar_path):
		install_failed.emit("server_download")
		return
	Popups_Controller.instance.progress_scene.close_popup()

	# 5. Limpieza
	DirAccess.remove_absolute(jdk_zip)
	_remove_dir_recursive(jdk_extract)
	onComplete.call()
	install_finished.emit()

func _download(url: String, target: String) -> bool:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.download_file = target
	var done := [false, false]
	_http.request_completed.connect(func(result, code, headers, body):
		done[0] = true
		done[1] = (result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 400)
	)
	if _http.request(url) != OK:
		_http.queue_free()
		return false
	set_process(true)
	while not done[0]:
		await get_tree().process_frame
	set_process(false)
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

func _fetch_hash(hash_url: String) -> String:
	var req := HTTPRequest.new()
	add_child(req)
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
		await get_tree().process_frame
	req.queue_free()
	return result[0]

func _verify_hash(path: String, expected: String) -> bool:
	if expected.is_empty():
		return false
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
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

func _process(_delta: float) -> void:
	if _http and _http.get_http_client_status() == HTTPClient.STATUS_BODY:
		var total := _http.get_body_size()
		var got := _http.get_downloaded_bytes()
		if total > 0:
			var pct := float(got) / float(total) * 100.0
			install_progress.emit(pct)
			if Popups_Controller.instance.progress_scene:
				Popups_Controller.instance.progress_scene.set_progress(pct)

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
		await get_tree().create_timer(0.2).timeout
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
		await get_tree().process_frame
	reader.close()
	return true

func _move_jdk_contents(extract_dir: String, jdk_dir: String) -> bool:
	var da := DirAccess.open(extract_dir)
	if da == null: return false
	da.list_dir_begin()
	var inner := ""
	var name := da.get_next()
	while name != "":
		if da.current_is_dir() and not name.begins_with("."):
			inner = extract_dir.path_join(name)
			break
		name = da.get_next()
	da.list_dir_end()
	if inner == "": return false
	return _move_all(inner, jdk_dir)

func _move_all(from_dir: String, to_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(to_dir)
	var da := DirAccess.open(from_dir)
	if da == null: return false
	da.list_dir_begin()
	var name := da.get_next()
	while name != "":
		if name != "." and name != "..":
			var src := from_dir.path_join(name)
			var dst := to_dir.path_join(name)
			if da.current_is_dir():
				_move_all(src, dst)
			else:
				DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
				da.rename(src, dst)
		name = da.get_next()
	da.list_dir_end()
	return true

func _chmod_java() -> void:
	OS.execute("chmod", ["+x", _java_path()])

func _remove_dir_recursive(path: String) -> void:
	var da := DirAccess.open(path)
	if da == null: return
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

func start_heartbeat_loop():
	if is_instance_valid(heartbeat_timer):
		heartbeat_timer.queue_free()
	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = HEARTBEAT_INTERVAL
	heartbeat_timer.autostart = true
	heartbeat_timer.timeout.connect(_on_heartbeat_timer_timeout)
	add_child(heartbeat_timer)
	Log.d("[NETWORK] Heartbeat loop started every %d s" % HEARTBEAT_INTERVAL)

func _on_heartbeat_timer_timeout():
	if current_sessid == "":
		return
	var success = await NetworkHandler.send_heartbeat()
	if not success:
		Log.d("[WARNING] Heartbeat failed, retrying next cycle")