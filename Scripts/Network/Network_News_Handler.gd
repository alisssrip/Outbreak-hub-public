class_name Network_News_Handler
extends Node

var NEWS_URL := Network_Handler.get_web_backend_api() + "article/get"
const LAUNCHER_CATEGORIES := [3, 4]
const PAGE_SIZE           := 10

var _http: HTTPRequest
var _all_news: Array[ArticleData] = []
var _page: int  = 0
var _loading: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)

func fetch(on_done: Callable) -> void:
	if _loading:
		return
	_loading = true
	_page    = 0
	_all_news.clear()

	var headers = ["Accept-Encoding: identity"]
	var err = _http.request(NEWS_URL, headers)
	if err != OK:
		push_error("News request falló: %d" % err)
		_loading = false
		var empty : Array[ArticleData] = []
		on_done.call(empty, false)
		return

	var response = await _http.request_completed
	_loading = false

	Log.d("response[0] (result): ", response[0])
	Log.d("response[1] (code): ", response[1])
	Log.d("response[3] size: ", response[3].size() if response[3] else "NULL")

	var code: int = response[1]
	var raw_bytes: PackedByteArray = response[3]
	var body: String = ""

	var decompressed = raw_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if decompressed.size() > 0:
		body = decompressed.get_string_from_utf8()
		Log.d("descomprimido OK, size: ", decompressed.size())
	else:
		body = raw_bytes.get_string_from_utf8()

	Log.d("body preview: ", body.substr(0, 200))

	if code != 200:
		push_error("News HTTP error: %d" % code)
		var empty : Array[ArticleData] = []
		on_done.call(empty, false)
		return

	var raw = JSON.parse_string(body)
	if not raw is Array:
		push_error("News: respuesta no es Array")
		var empty : Array[ArticleData] = []
		on_done.call(empty, false)
		return

	for item in raw:
		var category := int(item.get("category", -1))
		if category in LAUNCHER_CATEGORIES:
			var data := ArticleData.new()
			data.title = item.get("title", "")
			data.description = item.get("description", "")
			data.image_url = item.get("imagePath", "")
			_all_news.append(data)
	_all_news.reverse()
	var page_data = _get_page(0)
	await _load_images_for(page_data)

	var has_more = _all_news.size() > PAGE_SIZE
	on_done.call(page_data, has_more)


func _load_images_for(data: Array[ArticleData]) -> void:
	for item in data:
		await _load_single_image(item)


func _load_single_image(data: ArticleData) -> void:
	if data.image_url.is_empty():
		return

	var http := HTTPRequest.new()
	add_child(http)

	var err = http.request(data.image_url)
	if err != OK:
		http.queue_free()
		return

	var response = await http.request_completed
	http.queue_free()

	var code  : int             = response[1]
	var bytes : PackedByteArray = response[3]

	if code != 200 or bytes.size() == 0:
		return

	var image := Image.new()
	var result := image.load_png_from_buffer(bytes)
	if result != OK:
		result = image.load_jpg_from_buffer(bytes)
	if result != OK:
		result = image.load_webp_from_buffer(bytes)
	if result != OK:
		return

	data.sprite = ImageTexture.create_from_image(image)

func load_more(on_done: Callable) -> void:
	_page += 1
	var page_data = _get_page(_page)
	var has_more  = (_page + 1) * PAGE_SIZE < _all_news.size()
	on_done.call(page_data, has_more)

func _get_page(page: int) -> Array[ArticleData]:
	var start  := page * PAGE_SIZE
	var end    := mini(start + PAGE_SIZE, _all_news.size())
	var result : Array[ArticleData] = []
	for i in range(start, end):
		result.append(_all_news[i])
	return result

func load_image_for(data: ArticleData, on_done: Callable) -> void:
	if data.image_url.is_empty():
		on_done.call(null)
		return

	var http := HTTPRequest.new()
	add_child(http)

	var err = http.request(data.image_url)
	if err != OK:
		http.queue_free()
		on_done.call(null)
		return

	var response = await http.request_completed
	http.queue_free()

	var code : int = response[1]
	if code != 200:
		on_done.call(null)
		return

	var bytes  : PackedByteArray = response[3]
	var image  := Image.new()
	var result := image.load_png_from_buffer(bytes)

	if result != OK:
		result = image.load_jpg_from_buffer(bytes)
	if result != OK:
		result = image.load_webp_from_buffer(bytes)

	if result != OK:
		on_done.call(null)
		return

	on_done.call(ImageTexture.create_from_image(image))
