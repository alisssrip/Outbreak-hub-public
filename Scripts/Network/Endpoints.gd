class_name Endpoints
extends RefCounted

const CONFIG_PATH := "res://endpoints.cfg"
const SECTION := "endpoints"

static var _cfg: ConfigFile = null
static var _loaded: bool = false

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		_cfg = cfg
	else:
		push_warning("endpoints.cfg missing")

static func get_value(key: String, fallback: Variant = "") -> Variant:
	_load()
	if _cfg == null:
		return fallback
	return _cfg.get_value(SECTION, key, fallback)

static func get_url(key: String) -> String:
	return str(get_value(key, ""))

static func outbreak_backend_api() -> String:
	return get_url("outbreak_backend_api")

static func outbreak_backend_api_dev() -> String:
	return get_url("outbreak_backend_api_dev")

static func outbreak_backend_ws() -> String:
	return get_url("outbreak_backend_ws")

static func outbreak_backend_ws_dev() -> String:
	return get_url("outbreak_backend_ws_dev")

static func web_backend_api() -> String:
	return get_url("web_backend_api")

static func resource_base() -> String:
	return get_url("resource_base")

static func website() -> String:
	return get_url("website")

static func game_servers() -> Dictionary:
	return get_value("game_servers", {})

static func ps2_dns() -> String:
	return get_url("ps2_dns")
