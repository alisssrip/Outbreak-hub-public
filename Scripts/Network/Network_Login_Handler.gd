class_name Network_Login_Handler
extends Node

var _web_backend_token : String = ""
var _http : HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)

func login(username: String, password: String) -> String:
	var err = _http.request(
		Network_Handler.get_web_backend_api() + "user/login",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"Username": username, "Password": password})
	)

	if err != OK:
		push_error("Request falló: %d" % err)
		return "connection"

	var response = await _http.request_completed
	var code = response[1]
	var body = response[3].get_string_from_utf8()

	Log.d("auth code: ", code)
	if OS.is_debug_build():
		Log.d("auth body: ", body)

	if code == 401: return "credential"
	if code != 200: return "connection"

	var data = JSON.parse_string(body)
	_web_backend_token = data["token"]

	return await _launcher_login()

func _launcher_login() -> String:
	var err = _http.request(
		(Network_Handler.get_outbreak_backend_api() + "/auth/outbreak-hub"),
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"token": _web_backend_token})
	)

	if err != OK:
		push_error("Launcher request falló: %d" % err)
		return "launcher_error"

	var response = await _http.request_completed
	var code = response[1]
	var body = response[3].get_string_from_utf8()

	Log.d("launcher code: ", code)
	if OS.is_debug_build():
		Log.d("launcher body: ", body)

	if code != 200:
		return "launcher_error"

	var body_string: String = ""
	if body is PackedByteArray:
		body_string = body.get_string_from_utf8().strip_edges()
	else:
		body_string = str(body).strip_edges()

	var data = JSON.parse_string(body_string)

	if data == null:
		push_error("launcher json parse failed")
		return "json_parse_error"

	RpcModules.user.user_id = data["userId"]
	RpcModules.user.nickname = data["nickname"]
	NetworkHandler.token = data["token"]

	Log.d("connecting with token: ", _web_backend_token.substr(0, 20))
	RpcClient.connect_to_server(data["token"]) 
	Log.d("waiting for connected...")
	await RpcClient.connected
	Log.d("connected!")

	return ""

func simulate_login(user_id: int) -> String:
	if not OS.is_debug_build():
		push_error("simulate_login: debug only")
		return "dev_only"

	var err = _http.request(
		NetworkHandler.get_outbreak_backend_api() + "/auth/dev-login",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({"userId": user_id})
	)
	if err != OK: return "connection"

	var response = await _http.request_completed
	var code = response[1]
	var body = response[3].get_string_from_utf8()
	Log.d("dev-login code: ", code)
	if code != 200: return "launcher_error"

	var data = JSON.parse_string(body)
	_web_backend_token = data["token"]
	NetworkHandler.token = data["token"]    # ← AGREGAR
	RpcModules.user.user_id = data["userId"]
	RpcModules.user.nickname = data["nickname"]

	RpcClient.connect_to_server(_web_backend_token)
	await RpcClient.connected
	return ""
