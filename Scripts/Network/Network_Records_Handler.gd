class_name Network_Records_Handler
extends Node

var BASE_URL := Network_Handler.get_outbreak_backend_api() + "/api/records"

func submit_record(record: Dictionary, on_done: Callable) -> void:
	await _make_request(
		BASE_URL,
		HTTPClient.METHOD_POST,
		JSON.stringify(record),
		on_done
	)

func get_records(user_id: int, on_done: Callable) -> void:
	await _make_request(
		"%s/%d/records" % [BASE_URL, user_id],
		HTTPClient.METHOD_GET,
		"",
		on_done
	)

func get_history(user_id: int, on_done: Callable) -> void:
	await _make_request(
		"%s/%d/history" % [BASE_URL, user_id],
		HTTPClient.METHOD_GET,
		"",
		on_done
	)

func get_match_detail(gamenr: int, on_done: Callable) -> void:
	await _make_request(
		"%s/match/%d" % [BASE_URL, gamenr],
		HTTPClient.METHOD_GET,
		"",
		on_done
	)

func get_match_entry(match_id: int, on_done: Callable) -> void:
	await _make_request(
		"%s/entry/%d" % [BASE_URL, match_id],
		HTTPClient.METHOD_GET,
		"",
		on_done
	)
func get_rank(scenario: int, time: int, final_state: int, cleared: bool, on_done: Callable) -> void:
	var query := "?scenario=%d&time=%d&finalState=%d&cleared=%s" % [scenario, time, final_state, str(cleared).to_lower()]
	await _make_request(
		BASE_URL + "/rank" + query,
		HTTPClient.METHOD_GET,
		"",
		on_done
	)

func _make_request(url: String, method: int, body: String, on_done: Callable) -> void:
	var headers = ["Content-Type: application/json", "Accept-Encoding: identity"]
	if NetworkHandler.token != "":
		headers.append("Authorization: Bearer " + NetworkHandler.token)
	var http := HTTPRequest.new()
	http.timeout = 10.0
	add_child(http)
	var err = http.request(url, headers, method, body)
	if err != OK:
		http.queue_free()
		on_done.call(0, null)
		return
	var response = await http.request_completed
	http.queue_free()
	var code : int = response[1]
	var bytes : PackedByteArray = response[3]
	if code != 200 and code != 201:
		on_done.call(code, null)
		return
	on_done.call(code, JSON.parse_string(bytes.get_string_from_utf8()))