class_name MV_ServerModule
extends MV_BaseModule

@export var selected_server := 0
@export var server_buttons: Array[CheckButton] = []
@export var server_ping_label: Array[Label] = []
@export var start_server : Button
@export var stop_server : Button
@export var description_text : RichTextLabel
@export var ok_color : Color
@export var error_color : Color
@export var serverError : String
@export var serverConnected : String
@export var descriptionText : String
@export var tutorial : RichTextLabel
@export var download_button : Button

@export var own_server_panel : Control
@export var download_java_server : Control

var SERVERS := Endpoints.game_servers()

const TEST_PORT = 8690
const TIMEOUT_MS = 2000

var ping_times = {
	"AR": -1,
	"USA": -1,
	"JAP": -1,
	"GER": -1
}

var thread: Thread
var mutex: Mutex
var loop_active: bool = true

func initState(hndlr : MainViewComponentSystem) -> MV_BaseModule:
	ctx = hndlr
	return self

func _ready() -> void:
	mutex = Mutex.new()
	thread = Thread.new()
	var error = thread.start(Callable(self, "_ping_loop"))
	Log.d("thread start result: ", error)

	for i in server_buttons.size():
		server_buttons[i].toggled.connect(_on_server_toggled.bind(i))

	_select_server(SettingsManager.settings.selected_server)
	start_server.pressed.connect(_start_server)
	stop_server.pressed.connect(_stop_server)
	stop_server.hide()
	tutorial.meta_clicked.connect(_on_link_clicked)
	download_button.pressed.connect(download_pressed)

	set_process(true)

func _process(_delta: float) -> void:
	for i in server_ping_label.size():
		var ms := get_ping(_get_region(i))
		if ms < 0:
			server_ping_label[i].text = "-- ms"
		else:
			server_ping_label[i].text = "%d ms" % ms

func _on_link_clicked(meta: Variant) -> void:
	var url := str(meta)
	Popups_Controller.instance.show_confirm(tr("POPUP_OPEN_BROWSER"), func(): OS.shell_open(url))

func _on_server_selected(index: int) -> void:
	SettingsManager.settings.selected_server = index
	SettingsManager.save_settings()
	_select_server(index)

func _start_server() -> void:
	var java = LauncherController.instance.java
	if not java.is_installed():
		Log.d("[SERVER] files missing, back to download panel")
		_set_offline_text()
		show_download_panel(true)
		return

	start_server.disabled = true
	var last_name = start_server.text
	start_server.text = tr("SERVER_STARTING")

	NetworkHandler.REGION = "PS"

	if await java.launch_and_verify_server():
		if not NetworkHandler.emulator.has_session():
			await NetworkHandler.emulator.open_session()
		var registered := await NetworkHandler.register_session_in_master()
		if not registered:
			Log.d("[SERVER] gameserver registration failed")

		description_text.add_theme_color_override("default_color", ok_color)
		description_text.text = tr(serverConnected)
		start_server.hide()
		start_server.disabled = false
		start_server.text = last_name
		stop_server.text = tr("COMMON_STOP")
		stop_server.show()
	else:
		_select_server(SettingsManager.settings.selected_server)
		description_text.add_theme_color_override("default_color", error_color)
		description_text.text = tr(serverError)
		start_server.disabled = false
		start_server.text = last_name
		show_download_panel(not java.is_installed())

func _stop_server() -> void:
	Popups_Controller.instance.show_confirm(tr("SERVER_STOP_CONFIRM"), _do_stop_server)

func _do_stop_server() -> void:
	stop_server.disabled = true
	stop_server.text = tr("SERVER_STOPPING")
	await NetworkHandler.unregister_session_in_master()
	var stopped: bool = await LauncherController.instance.java.kill_server_async()
	stop_server.disabled = false
	stop_server.text = tr("COMMON_STOP")
	if not stopped:
		Popups_Controller.instance.show_error(tr("POPUP_SERVER_TITLE"), tr("SERVER_STOP_FAILED"))
		return
	_select_server(SettingsManager.settings.selected_server)
	stop_server.hide()
	start_server.show()
	_set_offline_text()

func _set_offline_text() -> void:
	description_text.add_theme_color_override("default_color", error_color)
	description_text.text = tr(descriptionText) + tr("BADGE_OFFLINE")

func startState() -> void:
	_select_server(SettingsManager.settings.selected_server)
	_open_window()
	var running: bool = LauncherController.instance.java.refresh_status()
	if running:
		start_server.hide()
		stop_server.show()
		stop_server.text = tr("COMMON_STOP")
		description_text.add_theme_color_override("default_color", ok_color)
		description_text.text = tr(serverConnected)
	else:
		start_server.show()
		stop_server.hide()
		_set_offline_text()
	show_download_panel(!LauncherController.instance.java.is_installed())

func download_pressed() -> void:
	Popups_Controller.instance.show_confirm(tr("SERVER_DOWNLOAD_CONFIRM"),
	func():
		LauncherController.instance.java.install_dependencies(func(): show_download_panel(false))
		)

func show_download_panel(show: bool) -> void:
	if show:
		own_server_panel.hide()
		download_java_server.show()
	else:
		own_server_panel.show()
		download_java_server.hide()

func _on_server_toggled(pressed: bool, index: int) -> void:
	if pressed:
		SettingsManager.settings.selected_server = index
		_select_server(index)
		SettingsManager.save_settings()

func _select_server(index: int) -> void:
	if index >= 0 and index < server_buttons.size():
		server_buttons[index].button_pressed = true
		var region = _get_region(index)
		NetworkHandler.REGION = region

func _get_region(index: int) -> String:
	match index:
		0: return "AR"
		1: return "USA"
		2: return "GER"
		3: return "JAP"
		_: return "AR"

func _ping_loop() -> void:
	while loop_active:
		var new_pings = {}
		for region in SERVERS:
			if not loop_active: break
			new_pings[region] = _measure_ping(SERVERS[region])
		mutex.lock()
		for region in new_pings:
			ping_times[region] = new_pings[region]
		mutex.unlock()
		for i in range(50):
			if not loop_active: break
			OS.delay_msec(100)

func _measure_ping(ip: String) -> int:
	var icmp := _icmp_ping(ip)
	if icmp >= 0:
		return icmp
	return _tcp_ping(ip)

func _icmp_ping(ip: String) -> int:
	var output = []
	var args: Array
	var exit: int
	if OS.get_name() == "Windows":
		args = ["-n", "1", "-w", "2000", ip]
		exit = OS.execute("ping", args, output)
	else:
		exit = OS.execute("sh", ["-c", "LC_ALL=C ping -c 1 -W 2 " + ip], output)
	if exit != 0 or output.is_empty():
		return -1
	return _parse_ping(output[0])

func _tcp_ping(ip: String) -> int:
	var peer := StreamPeerTCP.new()
	var start := Time.get_ticks_msec()
	if peer.connect_to_host(ip, TEST_PORT) != OK:
		return -1
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		peer.poll()
		if Time.get_ticks_msec() - start > TIMEOUT_MS:
			peer.disconnect_from_host()
			return -1
		OS.delay_msec(5)
	var elapsed := Time.get_ticks_msec() - start
	var ok := peer.get_status() == StreamPeerTCP.STATUS_CONNECTED
	peer.disconnect_from_host()
	if not ok:
		return -1
	return elapsed

func _parse_ping(text: String) -> int:
	var markers = ["time=", "tiempo=", "time<", "tiempo<"]
	for marker in markers:
		var idx = text.find(marker)
		if idx != -1:
			var sub = text.substr(idx + marker.length())
			var num = ""
			for c in sub:
				if c.is_valid_int() or c == ".":
					num += c
				else:
					break
			if num != "":
				return int(num.to_float())
	return -1

func get_ping(region: String) -> int:
	var value = -1
	mutex.lock()
	if ping_times.has(region):
		value = ping_times[region]
	mutex.unlock()
	return value

func _exit_tree() -> void:
	loop_active = false
	if thread and thread.is_started():
		thread.wait_to_finish()

func updateState() -> void:
	return

func exitState() -> void:
	_close_window()

func _global_btn_pressed() -> void:
	return
