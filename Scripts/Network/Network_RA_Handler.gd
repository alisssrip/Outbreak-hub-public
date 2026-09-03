extends Node
class_name Network_RA_Handler

const RA_LOGIN_URL := "https://retroachievements.org/dorequest.php"
const USER_AGENT := "Alissrip/1.0.0 (Linux) Integration/1.0.0"

func login(username: String, password: String, on_done: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	var query := "?r=login&u=%s&p=%s" % [username.uri_encode(), password.uri_encode()]
	var headers := ["User-Agent: " + USER_AGENT, "Content-Type: application/x-www-form-urlencoded"]
	var err := http.request(RA_LOGIN_URL + query, headers, HTTPClient.METHOD_POST, "")
	if err != OK:
		http.queue_free()
		on_done.call(null)
		return
	var result = await http.request_completed
	http.queue_free()
	var code = result[1]
	var body = result[3].get_string_from_utf8()
	if code != 200:
		on_done.call(null)
		return
	var json = JSON.parse_string(body)
	if json == null or not json.get("Success", false):
		on_done.call(null)
		return
	on_done.call({
		"token": str(json.get("Token", "")),
		"user": str(json.get("User", ""))
	})

func verify_token(username: String, token: String, on_done: Callable) -> void:
	if username == "" or token == "":
		on_done.call(false)
		return
	var http := HTTPRequest.new()
	add_child(http)
	var query := "?r=login&u=%s&t=%s" % [username.uri_encode(), token.uri_encode()]
	var headers := ["User-Agent: " + USER_AGENT, "Content-Type: application/x-www-form-urlencoded"]
	var err := http.request(RA_LOGIN_URL + query, headers, HTTPClient.METHOD_POST, "")
	if err != OK:
		http.queue_free()
		on_done.call(false)
		return
	var result = await http.request_completed
	http.queue_free()
	if result[1] != 200:
		on_done.call(false)
		return
	var json = JSON.parse_string(result[3].get_string_from_utf8())
	if json == null:
		on_done.call(false)
		return
	on_done.call(bool(json.get("Success", false)))
