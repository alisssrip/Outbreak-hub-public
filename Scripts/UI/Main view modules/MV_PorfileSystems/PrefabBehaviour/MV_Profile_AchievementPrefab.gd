class_name MV_Profile_AchievementPrefab
extends Panel

const HARDCORE_COLOR := Color(0.9, 0.35, 0.35)
const NOT_ACHIEVED := "ACH_NOT_ACHIEVED"

@export var icon_rect : TextureRect
@export var title_label : Label
@export var desc_rich : Label
@export var date_label : Label
@export var percent_label : Label
@export var hardcore_percent_label : Label

@export_category("Status Textures")
@export var status_rect : TextureRect
@export var status_locked : Texture2D
@export var status_unlocked : Texture2D
@export var status_hardcore : Texture2D

var _data : MV_Profile_AchievementsData

func setup(data: MV_Profile_AchievementsData) -> void:
	_data = data
	title_label.text = data.title
	desc_rich.text = data.description
	percent_label.text = tr("ACH_NORMAL_PCT") % data.percentage
	if hardcore_percent_label:
		hardcore_percent_label.text = tr("ACH_HARD_PCT") % data.hardcore_percentage
		hardcore_percent_label.add_theme_color_override("font_color", HARDCORE_COLOR)
	if data.unlocked:
		icon_rect.modulate = Color.WHITE
		date_label.text = _format_date(data.date)
	else:
		icon_rect.modulate = Color(0.3, 0.3, 0.3, 1.0)
		date_label.text = tr(NOT_ACHIEVED)
	_apply_status(data)
	if data.icon != null:
		icon_rect.texture = data.icon
	elif data.badge_url != "":
		_load_badge(data.badge_url)

func _apply_status(data: MV_Profile_AchievementsData) -> void:
	if status_rect == null:
		return
	if data.unlocked_hardcore and status_hardcore != null:
		status_rect.texture = status_hardcore
	elif data.unlocked and status_unlocked != null:
		status_rect.texture = status_unlocked
	elif status_locked != null:
		status_rect.texture = status_locked

func _format_date(raw: String) -> String:
	if raw == "" or raw == "null":
		return tr(NOT_ACHIEVED)
	var date_part := raw.split(" ")[0]
	var parts := date_part.split("-")
	if parts.size() < 3:
		return date_part
	return "%s/%s/%s" % [parts[2], parts[1], parts[0]]

func _load_badge(url: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_badge_downloaded.bind(http))
	var err := http.request(url)
	if err != OK:
		http.queue_free()

func _on_badge_downloaded(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var img := Image.new()
	if img.load_png_from_buffer(body) != OK:
		return
	var tex := ImageTexture.create_from_image(img)
	icon_rect.texture = tex
	if _data != null:
		_data.icon = tex

func is_same_data(data: MV_Profile_AchievementsData) -> bool:
	return _data == data