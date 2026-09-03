class_name LauncherController extends Node

static var instance: LauncherController

@export var stateController : State_Controller
@export var java : JavaServerController
@export var simulateLoginUserId : int = 16
@export var dragger: DragWindow
@export var results: GameResultsController
@export var game_details: MV_GameBreakdown
@export var character: CharacterStore

var joysticks_connected: int = 0 


var records: RecordsController
var _sysctl: SystemController

var _pending_update : Dictionary = {}

var _last_status: String

var EMULATOR_RUNNING : bool
var _guide_shown_this_run : bool = false

signal emulator_opened()
signal emulator_closed()
signal on_joystick_connected(connected: bool, device: int)

const SIMULATE_LOGIN : bool = false
static func guide_url() -> String:
	return Endpoints.website() + "/navigation-guide"

static func setup_guide_url() -> String:
	return Endpoints.website() + "/setup-guide"

const BLOCK_JOYSTICK_INPUT: bool = true

const BASE_STATUSES: Array[String] = ["online", "afk", "busy"]

func _enter_tree() -> void:
	if instance != null:
		push_error("LauncherController already exists")
		queue_free()
		return
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_tree().root.close_requested.connect(_on_close_requested)

	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	joysticks_connected = Input.get_connected_joypads().size()

	Pcsx2Manager.emulator_opened.connect(_on_emulator_opened)
	Pcsx2Manager.emulator_closed.connect(_on_emulator_closed)
	stateController._init_state_machine()
	RpcModules.ingame.own_room_entered.connect(RpcModules.ingame_status.start_match)
	RpcModules.ingame.own_match_started.connect(RpcModules.ingame_status.on_match_started)
	RpcModules.ingame.own_match_ended.connect(RpcModules.ingame_status.end_match)
	RpcModules.ingame.own_match_cancelled.connect(RpcModules.ingame_status.stop_match)
	records = RecordsController.new()
	records.init(RpcModules.ingame_status)
	_sysctl = SystemController.new()
	add_child(_sysctl)
	RpcModules.ingame_status.record_finalized.connect(_on_match_finalized)
	if results and results.closeButton:
		results.closeButton.pressed.connect(_on_results_closed)
	UpdaterController.progress.connect(_on_update_progress)
	UpdaterController.finished.connect(_on_update_finished)
	UpdaterController.failed.connect(_on_update_failed)
	RpcModules.launcher.update_available.connect(_on_update_available)
	RpcModules.ingame.own_match_ended.connect(_on_match_ended_for_update)
	RpcClient.event_received.connect(_on_rpc_event)
	ResolutionController._set_specific_res(SettingsManager.settings.resolution)
	dragger._set_version(RpcModules.launcher.VERSION)
	_check_version_on_startup()

func _launch_game() -> void:
	Pcsx2Manager.achievements.repair_if_needed()
	if(joysticks_connected <= 0): 
		Popups_Controller.instance.show_error(tr("POPUP_NO_GAMEPAD_TITLE"), tr("POPUP_NO_GAMEPAD_MSG"))
		return
	if !Pcsx2Manager.files.is_installed():
		Popups_Controller.instance.show_confirm(tr("POPUP_PCSX2_DOWNLOAD"),
		func():
			Pcsx2Manager.files.install())
		return

	if not _guide_notice_accepted():
		return

	var s = SettingsManager.settings
	if not _apply_all_settings():
		push_error("failed to apply settings")
		return

	var iso = s.game_path
	if not Pcsx2Manager.launch.launch_game(iso):
		push_error("launch failed")
		return
	return

func _guide_notice_accepted() -> bool:
	if _guide_shown_this_run:
		return true
	if SettingsManager.settings.guide_shown == 1 and not OS.has_feature("editor"):
		return true
	Popups_Controller.instance.show_confirm(
		tr("POPUP_GUIDE_NOTICE"),
		func():
			_guide_shown_this_run = true
			SettingsManager.settings.guide_shown = 1
			SettingsManager.save_settings()
			OS.shell_open(guide_url()),
		false)
	return false

func _apply_all_settings() -> bool:
	var s = SettingsManager.settings
	if s.is_advanced_enabled():
		return true
	var failed : Array[String] = []
	if not Pcsx2Manager.graphics.apply(s):
		failed.append(tr("SETTINGS_PART_GRAPHICS"))
	if not Pcsx2Manager.controls.apply(s):
		failed.append(tr("SETTINGS_PART_CONTROLS"))
	if not Pcsx2Manager.anticheat.apply():
		failed.append(tr("SETTINGS_PART_ANTICHEAT"))
	if not Pcsx2Manager.achievements.repair_if_needed():
		failed.append(tr("SETTINGS_PART_ACHIEVEMENTS"))
	if failed.is_empty():
		return true
	Log.d("[LAUNCH] settings failed: ", failed)
	Popups_Controller.instance.show_error(tr("POPUP_EMULATOR_ERROR_TITLE"),
		tr("POPUP_SETTINGS_APPLY_FAILED") % ", ".join(failed))
	return false

func _on_close_requested() -> void:
	Log.d("[CLOSE] window close requested")
	_shutdown_sync()
	Log.d("[CLOSE] shutdown done")
	get_tree().quit()

func _shutdown_sync() -> void:
	Log.d("[SHUTDOWN] Cleaning up")
	if is_instance_valid(java) and java.SERVER_STATUS:
		NetworkHandler.unregister_session_sync()
		java.kill_server()
	if EMULATOR_RUNNING:
		Pcsx2Manager.launch.kill()
		Pcsx2Manager.stop_monitoring()
	if NetworkHandler.emulator.has_session():
		NetworkHandler.emulator.close_session_sync()
	SettingsManager.save_settings()
	Log.d("[SHUTDOWN] Done")

func _test_anticheat() -> void:
	Pcsx2Manager.anticheat.apply()
	var content: String = Pcsx2Manager.ini.read("PCSX2.ini")
	if OS.is_debug_build():
		Log.d(_extract_section(content, "[EmuCore]"))
		Log.d("---")
		Log.d(_extract_section(content, "[EmuCore/Speedhacks]"))
		Log.d("---")
		Log.d(_extract_section(content, "[Hotkeys]"))

func _extract_section(text: String, header: String) -> String:
	var lines := text.split("\n")
	var out := ""
	var capturing := false
	for line in lines:
		var stripped := line.strip_edges()
		if stripped == header:
			capturing = true
			out += line + "\n"
			continue
		if capturing and stripped.begins_with("[") and stripped.ends_with("]"):
			break
		if capturing:
			out += line + "\n"
	return out

func _on_emulator_opened() -> void:
	EMULATOR_RUNNING = true
	AudioController.set_bgm_volume(0)
	emulator_opened.emit()
	var session_error : String = await NetworkHandler.emulator.open_session()
	if session_error != "":
		Log.d("[SESSION] open failed: ", session_error)
	if java.SERVER_STATUS:
		await NetworkHandler.register_session_in_master()
	_last_status = _sanitize_base_status(RpcModules.user.status)
	RpcModules.ingame.set_base("in_game_menu")

func _on_emulator_closed() -> void:
	EMULATOR_RUNNING = false
	AudioController.set_bgm_volume(0.3)
	emulator_closed.emit()
	RpcModules.ingame_status.stop_match()
	if java.SERVER_STATUS:
		await NetworkHandler.unregister_session_in_master()
	await NetworkHandler.emulator.close_session()
	RpcModules.ingame.set_base(_sanitize_base_status(_last_status))

func _sanitize_base_status(status: String) -> String:
	if BASE_STATUSES.has(status):
		return status
	return "online"

func _kill_emulator() -> void:
	Pcsx2Manager.launch.kill()
	Pcsx2Manager.stop_monitoring()
	if java.SERVER_STATUS:
		await NetworkHandler.unregister_session_in_master()
	NetworkHandler.emulator.close_session_sync()

func _check_version_on_startup() -> void:
	RpcModules.launcher.check_version(func(info):
		if info == null: return
		_prompt_update(info)
	)

func _on_update_available(info: Dictionary) -> void:
	if _is_in_game():
		_pending_update = info
		return
	_prompt_update(info)

func _on_match_ended_for_update() -> void:
	if _pending_update.is_empty(): return
	var info := _pending_update
	_pending_update = {}
	_prompt_update(info)

func _prompt_update(info: Dictionary) -> void:
	if EMULATOR_RUNNING:
		await _kill_emulator()
	var msg := tr("UPDATE_AVAILABLE") % str(info.get("version", ""))
	Popups_Controller.instance.show_confirm(
		msg,
		func(): _start_update(info),
		true,
		func(): get_tree().quit()
	)

func _start_update(info: Dictionary) -> void:
	if EMULATOR_RUNNING:
		await _kill_emulator()
	Popups_Controller.instance.show_progress(tr("UPDATE_IN_PROGRESS"), UpdaterController.cancel_download)
	UpdaterController.start_download(info)

func _on_update_progress(percent: float) -> void:
	if Popups_Controller.instance.progress_scene:
		Popups_Controller.instance.progress_scene.set_progress(percent)

func _on_update_finished() -> void:
	_shutdown_sync()
	UpdaterController.restart()

func _on_update_failed(reason: String) -> void:
	if Popups_Controller.instance.progress_scene:
		Popups_Controller.instance.progress_scene.close_popup()
	Popups_Controller.instance.show_error(tr("COMMON_ERROR"), tr("UPDATE_FAILED") % reason)
	LauncherController.instance._shutdown_sync()

func _is_in_game() -> bool:
	return str(RpcModules.ingame._last_own_phase) == "in_game"

func _on_match_finalized(record: Dictionary) -> void:
	_sysctl.bring_launcher_to_front()
	_sysctl.mute_emulator()
	if not results:
		return
	var sc : int = int(record.get("scenario", 0))
	var time_s : int = int(record.get("timeSeconds", 0))
	var final_state : int = int(record.get("finalState", 0))
	var cleared : bool = bool(record.get("cleared", false))
	NetworkHandler.records.get_rank(sc, time_s, final_state, cleared, func(code, data):
		if data != null and data.has("rank"):
			record["rank"] = int(data["rank"])
		results.show_results(record)
	)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	joysticks_connected = Input.get_connected_joypads().size()
	on_joystick_connected.emit(connected, device)

func _on_results_closed() -> void:
	_sysctl.unmute_emulator()

func _input(event):
	if BLOCK_JOYSTICK_INPUT:
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			get_viewport().set_input_as_handled()
func _on_rpc_event(method: String, _params: Dictionary) -> void:
	if method == "session.kicked":
		_on_session_kicked()

func _on_session_kicked() -> void:
	Popups_Controller.instance.show_confirm(
		tr("POPUP_SESSION_KICKED"),
		func():
			_shutdown_sync()
			get_tree().quit(),
		false
	)