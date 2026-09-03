extends Node

func _ready() -> void:
	Log.d("[SHUTDOWN_HANDLER] _ready called")
	get_tree().set_auto_accept_quit(false)
	get_tree().root.close_requested.connect(_on_close)

func _on_close() -> void:
	Log.d("[SHUTDOWN_HANDLER] CLOSE TRIGGERED")
	await _shutdown()
	get_tree().quit()

func _shutdown() -> void:
	Log.d("[SHUTDOWN] Cleaning up")
	DiscordPresence.shutdown()
	if LauncherController.instance != null and is_instance_valid(LauncherController.instance):
		var lc = LauncherController.instance
		if is_instance_valid(lc.java):
			if lc.java.SERVER_STATUS:
				await NetworkHandler.unregister_session_in_master()
			lc.java.kill_server()
		if lc.EMULATOR_RUNNING:
			Pcsx2Manager.launch.kill()
			Pcsx2Manager.stop_monitoring()
	if NetworkHandler.emulator != null and NetworkHandler.emulator.has_session():
		NetworkHandler.emulator.close_session_sync()
	Log.d("[SHUTDOWN] Done")