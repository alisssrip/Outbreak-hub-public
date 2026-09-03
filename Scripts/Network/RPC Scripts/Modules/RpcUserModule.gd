class_name RpcUserModule
extends RefCounted

var user_id     : int    = 0
var nickname    : String = ""
var status      : String = "offline"
var ranking     : int    = 0
var char_fav    : String = ""
var title       : String = ""
var playing_time: int = 0
var avatar_url  : String = ""

signal profile_loaded
signal status_changed(new_status: String)

func _ready() -> void:
	RpcClient.connected.connect(_on_connected)

func _on_connected() -> void:
	load_profile()

func fetch_profile(target_id: int, callback: Callable) -> void:
	RpcClient.call_rpc("user.getProfile", {"targetId": target_id}, func(result, err):
		if err or result == null:
			callback.call(null)
			return
		callback.call(result)
	)

func load_profile() -> void:
	RpcClient.call_rpc("user.getProfile", {}, func(result, err):
		if err: return
        
		nickname     = str(result.get("nickname", ""))
		status       = str(result.get("status", "offline"))
		ranking      = int(result.get("ranking", 0))
        
		var raw_char = result.get("charFav")
		char_fav     = str(raw_char) if raw_char != null else ""
        
		var raw_title = result.get("title")
		title        = str(raw_title) if raw_title != null else ""
        
		var raw_avatar = result.get("avatarUrl")
		avatar_url     = str(raw_avatar) if raw_avatar != null else ""
        
		Log.d("Avatar asignado con éxito: ", avatar_url)
        
		playing_time = int(result.get("playingTime", 0))
		profile_loaded.emit()
	)

func set_status(new_status: String) -> void:
	RpcClient.call_rpc("user.setStatus", {"status": new_status}, func(result, err):
		if not err:
			status = new_status
			if not RpcModules.user_store.is_ingame(user_id):
				RpcModules.user_store.update_user(user_id, {"phase": new_status, "status": new_status})
			status_changed.emit(new_status)
	)
