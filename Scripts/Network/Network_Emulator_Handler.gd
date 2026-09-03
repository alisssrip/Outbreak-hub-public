class_name Network_Emulator_Handler
extends Node

var _session_id : String = ""
var _session_token : String = ""
var _http : HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)


func open_session() -> String:
	var ipv4 := NetworkHandler.publicIP
	if ipv4 == "":
		Log.d("[SESSION] public IP empty, retrying fetch")
		ipv4 = await NetworkHandler.get_public_ip()
		NetworkHandler.publicIP = ipv4
	if ipv4 == "":
		Log.d("[SESSION] could not resolve public IP")
		return "ip_error"
	var body := JSON.stringify({"Token": NetworkHandler.token, "Region": NetworkHandler.REGION, "Ip": ipv4})
	var err = _http.request(
		NetworkHandler.get_outbreak_backend_api() + "/api/outbreakjava/sessions",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		return "connection"
	var response = await _http.request_completed
	var code = response[1]
	if code != 200:
		push_error("session create failed: " + str(code))
		return "session_error"
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	_session_id = str(data.get("sessionId", ""))
	NetworkHandler.current_sessid = _session_id
	return ""

func close_session() -> String:
	if _session_id == "":
		return "no_session"
	var url := NetworkHandler.get_outbreak_backend_api() + "/api/outbreakjava/sessions/" + _session_id + "?token=" + NetworkHandler.token
	var err = _http.request(url, [], HTTPClient.METHOD_DELETE)
	if err != OK:
		return "connection"
	var response = await _http.request_completed
	Log.d("delete code: " + str(response[1]))
	_session_id = ""
	return ""




func close_session_sync() -> void:
	if _session_id == "":
		return
	var base := NetworkHandler.get_outbreak_backend_api()
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
	var path := "/api/outbreakjava/sessions/" + _session_id + "?token=" + NetworkHandler.token
	http.request(HTTPClient.METHOD_DELETE, path, [])
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		OS.delay_msec(5)
	_session_id = ""

func has_session() -> bool:
	return _session_id != ""