extends Node
class_name Network_Handler

const GAME_PORT = 8690

var REGION = "AR"

const SKIP_DEV_AND_USE_PROD = true
const FORCE_DEV_WS = false

var current_sessid: String = ""

var is_processing_heartbeat = false

var token: String
@export var publicIP: String

var login : Network_Login_Handler
var news : Network_News_Handler
var profile : Network_Profile_Handler
var emulator : Network_Emulator_Handler
var records : Network_Records_Handler
var ra: Network_RA_Handler

func _ready():
	login = Network_Login_Handler.new()
	news = Network_News_Handler.new()
	profile = Network_Profile_Handler.new()
	emulator = Network_Emulator_Handler.new()
	records = Network_Records_Handler.new()
	ra = Network_RA_Handler.new()
	add_child(login)
	add_child(news)
	add_child(profile)
	add_child(emulator)
	add_child(records)
	add_child(ra)
	publicIP = await get_public_ip()

static func get_outbreak_backend_api() -> String:
	if OS.is_debug_build() and !SKIP_DEV_AND_USE_PROD:
		return Endpoints.outbreak_backend_api_dev()
	return Endpoints.outbreak_backend_api()

static func get_web_backend_api() -> String:
	return Endpoints.web_backend_api()

func sleep(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

func get_public_ip() -> String:
	var http := HTTPRequest.new()
	add_child(http)
	var err := http.request("https://api4.ipify.org")
	if err != OK:
		http.queue_free()
		return ""
	var result = await http.request_completed
	var status_code = result[1]
	var body = result[3].get_string_from_utf8().strip_edges()
	http.queue_free()
	if status_code == 200 and body != "":
		return body
	return ""

static func get_outbreak_backend_ws() -> String:
	if OS.is_debug_build() and !SKIP_DEV_AND_USE_PROD:
		return Endpoints.outbreak_backend_ws_dev()
	if FORCE_DEV_WS:
		return Endpoints.outbreak_backend_ws_dev()
	return Endpoints.outbreak_backend_ws()



func send_heartbeat() -> bool:
	if is_processing_heartbeat:
		return false

	is_processing_heartbeat = true

	var http = HTTPRequest.new()
	add_child(http)

	var url = get_outbreak_backend_api() + "/api/outbreakjava/gameservers/heartbeat?sessid=" + current_sessid.uri_encode()
	http.request(url, [], HTTPClient.METHOD_PUT, "")

	var response = await http.request_completed
	http.queue_free()

	is_processing_heartbeat = false

	var code = response[1]
	return code == 200 or code == 204

func register_session_in_master() -> bool:
	if current_sessid == "":
		Log.d("[ERROR] No session id. Login first")
		return false

	if publicIP == "":
		Log.d("[NETWORK] Public IP empty, retrying fetch")
		publicIP = await get_public_ip()
		if publicIP == "":
			Log.d("[ERROR] Could not resolve public IP")
			return false

	Log.d("[NETWORK] Registering gameserver %s:%d region %s" % [publicIP, GAME_PORT, REGION])

	var http = HTTPRequest.new()
	add_child(http)
	var headers = ["Content-Type: application/json"]
	var data = {
		"Sessid": current_sessid,
		"PublicIp": publicIP,
		"Port": GAME_PORT,
		"Region": REGION
	}

	http.request(get_outbreak_backend_api() + "/api/outbreakjava/gameservers/register", headers, HTTPClient.METHOD_POST, JSON.stringify(data))
	var response = await http.request_completed
	http.queue_free()

	var code = response[1]
	var body = response[3].get_string_from_utf8()

	match code:
		200:
			Log.d("[SUCCESS] Gameserver registered")
			return true
		400:
			Log.d("[ERROR] Port %d not reachable from outside. Check forwarding" % GAME_PORT)
			return false
		401:
			Log.d("[ERROR] Invalid session. Login again")
			return false
		_:
			if OS.is_debug_build():
				Log.d("[ERROR] Register failed. HTTP %d: %s" % [code, body])
			return false

func unregister_session_in_master() -> bool:
	if current_sessid == "":
		Log.d("[WARNING] No active session ID found to unregister.")
		return false

	var url = get_outbreak_backend_api() + "/api/outbreakjava/gameservers/unregister?sessid=" + current_sessid
	Log.d("[NETWORK] Unregistering gameserver from master server...")

	var http = HTTPRequest.new()
	add_child(http)

	var headers = []

	http.request(url, headers, HTTPClient.METHOD_DELETE)
	var response = await http.request_completed
	http.queue_free()

	var code = response[1]
	var body = response[3].get_string_from_utf8()

	match code:
		204:
			Log.d("[SUCCESS] Gameserver successfully unregistered from master.")
			return true
		401:
			Log.d("[ERROR] Unregister unauthorized. Session might be expired.")
			return false
		_:
			Log.d("[ERROR] Unregister failed. HTTP %d: %s" % [code, body])
			return false

func unregister_session_sync() -> void:
	if current_sessid == "":
		return
	var base := get_outbreak_backend_api()
	var use_tls := base.begins_with("https")
	var host := base.trim_prefix("https://").trim_prefix("http://")
	var port := 443 if use_tls else 80
	if host.contains(":"):
		var parts := host.split(":")
		host = parts[0]
		port = int(parts[1])
	host = host.trim_suffix("/")

	var http := HTTPClient.new()
	var err := http.connect_to_host(host, port, TLSOptions.client() if use_tls else null)
	if err != OK:
		return
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		OS.delay_msec(5)
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return
	var path := "/api/outbreakjava/gameservers/unregister?sessid=" + current_sessid
	http.request(HTTPClient.METHOD_DELETE, path, [])
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		OS.delay_msec(5)
