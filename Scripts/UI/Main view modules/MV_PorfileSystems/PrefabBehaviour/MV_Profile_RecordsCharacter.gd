class_name MV_Profile_RecordsCharacter
extends Panel

signal requested_open(node: MV_Profile_RecordsCharacter)
signal level_clicked(match_id: int, entry: Dictionary)

@export var collapsed_height : float = 78.0
@export var expanded_height : float = 380.0
@export var anim_time : float = 0.5
@export var name_background : Panel
@export var name_label : Label
@export var time_label : Label
@export var infection_label : Label
@export var difficulty_label : Label
@export var rank_label : Label
@export var show_button : Button
@export var levels : Array[MV_Profile_RecordLevel] = []

var _target_height : float = 0.0
var _smooth_speed : float = 0.0
var _open : bool = false

func _ready() -> void:
	_smooth_speed = 5.0 / max(anim_time, 0.01)
	_target_height = collapsed_height
	custom_minimum_size.y = collapsed_height
	size.y = collapsed_height
	if show_button:
		show_button.pressed.connect(_on_show_pressed)
	for lvl in levels:
		if lvl:
			lvl.clicked.connect(_on_level_clicked)
	_set_levels_interactable(false)

func setup(data: MV_Profile_RecordData) -> void:
	name_label.text = data.char_base
	time_label.text = tr("RECORD_TOTAL_TIME") % data.total_time
	infection_label.text = tr("RECORD_AVG_INFECTION") % data.avg_infection
	difficulty_label.text = data.difficulty
	rank_label.text = tr("RECORD_RANK") % data.rank
	var charStore = LauncherController.instance.character.store
	var characterBack: Texture2D
	for character in charStore:
		if character.character_name.to_upper() == data.char_base:
			characterBack = character.record
			break
	var sb : StyleBox
	if characterBack != null:
		var textured := StyleBoxTexture.new()
		textured.texture = characterBack
		sb = textured
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color.BLACK
		sb = flat
	name_background.add_theme_stylebox_override("panel", sb)
	for lvl in levels:
		if lvl == null:
			continue
		var match_data := _find_level_data(data, lvl.scenario_id)
		if match_data != null:
			lvl.set_data(match_data)
		else:
			lvl.set_empty()
	_set_levels_interactable(_open)

func _find_level_data(data: MV_Profile_RecordData, sid: int) -> MV_Profile_RecordLevelData:
	for ld in data.levels:
		if ld.scenario == sid:
			return ld
	return null

func _process(delta: float) -> void:
	var current := custom_minimum_size.y
	if is_equal_approx(current, _target_height):
		return
	var next : float = lerp(current, _target_height, 1.0 - exp(-_smooth_speed * delta))
	if abs(next - _target_height) < 1.0:
		next = _target_height
	custom_minimum_size.y = next
	size.y = next

func _on_show_pressed() -> void:
	if _open:
		collapse()
	else:
		_open = true
		_target_height = expanded_height
		_set_levels_interactable(true)
		requested_open.emit(self)

func collapse() -> void:
	_open = false
	_target_height = collapsed_height
	_set_levels_interactable(false)

func _set_levels_interactable(enabled: bool) -> void:
	for lvl in levels:
		if lvl:
			lvl.set_interactable(enabled)

func _on_level_clicked(match_id: int, entry: Dictionary) -> void:
	level_clicked.emit(match_id, entry)
