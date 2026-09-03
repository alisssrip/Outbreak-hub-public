class_name Network_Profile_Handler
extends Node

var BASE_URL := Network_Handler.get_outbreak_backend_api() + "/api/profile"

var _http : HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)

func get_profile(user_id: int, on_done: Callable) -> void:
	var url = "%s/%d" % [BASE_URL, user_id]
	await _make_request(url, HTTPClient.METHOD_GET, "", on_done)

func get_records(user_id: int, on_done: Callable) -> void:
	await _make_request("%s/%d/records" % [BASE_URL, user_id], HTTPClient.METHOD_GET, "", on_done)

func set_ra_username(user_id: int, ra_username: String, on_done: Callable) -> void:
	_make_request(
		BASE_URL + "/%d/ra-link" % user_id,
		HTTPClient.METHOD_POST,
		JSON.stringify({"raUsername": ra_username}),
		on_done
	)


func set_favorite_char(user_id: int, character: String, on_done: Callable) -> void:
	await _make_request(
		"%s/%d/favorite-char" % [BASE_URL, user_id],
		HTTPClient.METHOD_POST,
		JSON.stringify({"character": character}),
		func(data):
			on_done.call(data != null)
	)
func set_status(user_id: int, status: String, on_done: Callable) -> void:
	await _make_request(
		"%s/%d/status" % [BASE_URL, user_id],
		HTTPClient.METHOD_POST,
		JSON.stringify({"status": status}),
		on_done
	)

func get_achievements(user_id: int, on_done: Callable) -> void:
	await _make_request("%s/%d/achievements" % [BASE_URL, user_id], HTTPClient.METHOD_GET, "", on_done)

func _make_request(url: String, method: int, body: String, on_done: Callable) -> void:
	var headers = ["Content-Type: application/json", "Accept-Encoding: identity"]
	if NetworkHandler.token != "":
		headers.append("Authorization: Bearer " + NetworkHandler.token)
	var http := HTTPRequest.new()
	http.timeout = 10.0
	add_child(http)
	var err = http.request(url, headers, method, body)
	if err != OK:
		push_error("request falló: %d" % err)
		http.queue_free()
		on_done.call(null)
		return
	var response = await http.request_completed
	http.queue_free()
	var code : int = response[1]
	var bytes : PackedByteArray = response[3]
	if code != 200:
		push_error("HTTP error: %d" % code)
		on_done.call(null)
		return
	on_done.call(JSON.parse_string(bytes.get_string_from_utf8()))

func load_image(url: String, on_done: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)

	var err = http.request(url)
	if err != OK:
		push_error("Error al iniciar la petición HTTP: %d" % err)
		http.queue_free()
		on_done.call(null)
		return

	var response = await http.request_completed
	http.queue_free()

	var result_code  = response[0]
	var http_code    = response[1]
	var headers      = response[2]
	var bytes        = response[3]

	if result_code != HTTPRequest.RESULT_SUCCESS or http_code != 200 or bytes.is_empty():
		push_error("Fallo la descarga de la imagen. Code: %d" % http_code)
		on_done.call(null)
		return

	var image := Image.new()
	var load_err := OK
	
	if url.to_lower().ends_with(".png"):
		load_err = image.load_png_from_buffer(bytes)
	elif url.to_lower().ends_with(".jpg") or url.to_lower().ends_with(".jpeg"):
		load_err = image.load_jpg_from_buffer(bytes)
	elif url.to_lower().ends_with(".webp"):
		load_err = image.load_webp_from_buffer(bytes)
	else:
		load_err = image.load_jpg_from_buffer(bytes)
		if load_err != OK: load_err = image.load_png_from_buffer(bytes)
		if load_err != OK: load_err = image.load_webp_from_buffer(bytes)

	if load_err != OK:
		push_error("No se pudo parsear el formato de la imagen. Error: %d" % load_err)
		on_done.call(null)
		return
	image.generate_mipmaps()
	var texture = ImageTexture.create_from_image(image)
	on_done.call(texture)

	on_done.call(ImageTexture.create_from_image(image))
	
func set_bio(user_id: int, bio: String, on_done: Callable) -> void:
	await _make_request(
		"%s/%d/bio" % [BASE_URL, user_id],
		HTTPClient.METHOD_POST,
		JSON.stringify({"bio": bio}),
		on_done
	)
