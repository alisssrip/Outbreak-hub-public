extends Node

const SOUNDS = {
	"Move-1": preload("res://Audio/Move-1.ogg"),
	"Move-2": preload("res://Audio/Move-2.ogg"),
	"Move-3": preload("res://Audio/Move-3.ogg"),
	"Select-1": preload("res://Audio/Select-1.ogg"),
	"Select-2": preload("res://Audio/Select-2.ogg"),
	"Select-3": preload("res://Audio/Select-3.ogg"),
	"Back-1": preload("res://Audio/Back-1.ogg"),
	"Writer": preload("res://Audio/Write.ogg"),
	"Error": preload("res://Audio/Error.ogg"),
	"Heartbeat": preload("res://Audio/Hearthbeat.ogg"),
	"BGM": preload("res://BGM.ogg")
}

const GROUP_SOUNDS = {
	"Button-Type-1": {"hover": "Move-2", "pressed": "Select-2", "select": "Select-2"},
	"Button-Type-2": {"hover": "Move-1", "pressed": "Select-2", "select": "Select-2"},
	"Button-Type-3": {"hover": "Move-3", "pressed": "Select-3", "select": "Select-3"},
	"Button-Toggle": {"pressed": "Select-1"},
	"Button-Back": {"hover": "Move-2", "pressed": "Back-1"},
	"Button-Field": {"pressed": "Select-2", "type": "Writer"}
}

const SFX_BUS = "SFX"
const BGM_BUS = "BGM"
const POLYPHONY = 16
const TYPE_COOLDOWN = 0.04

var _sfx: AudioStreamPlayer
var _bgm: AudioStreamPlayer
var _playback: AudioStreamPlaybackPolyphonic
var _sfx_bus := -1
var _bgm_bus := -1
var _bgm_tween: Tween
var _last_frame := -1
var _last_key := ""
var _last_type := 0.0

func _ready() -> void:
	_sfx_bus = _ensure_bus(SFX_BUS)
	_bgm_bus = _ensure_bus(BGM_BUS)
	if _sfx_bus < 0:
		push_error("Missing bus: " + SFX_BUS)
	if _bgm_bus < 0:
		push_error("Missing bus: " + BGM_BUS)
	_sfx = AudioStreamPlayer.new()
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = POLYPHONY
	_sfx.stream = poly
	_sfx.bus = SFX_BUS
	add_child(_sfx)
	_sfx.play()
	_playback = _sfx.get_stream_playback()
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = BGM_BUS
	add_child(_bgm)
	get_tree().node_added.connect(_on_node_added)
	_hook_tree(get_tree().root)
	play_bgm(SOUNDS["BGM"])
	set_bgm_volume(0.3)
	set_sfx_volume(0.3)
	debug_buses()

func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		return idx
	idx = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	push_warning("Bus created at runtime: " + bus_name)
	return idx

func play(sound_name: String) -> void:
	if not SOUNDS.has(sound_name):
		push_warning("Unknown sound: " + sound_name)
		return
	var frame := Engine.get_process_frames()
	if frame == _last_frame and sound_name == _last_key:
		return
	_last_frame = frame
	_last_key = sound_name
	_playback.play_stream(SOUNDS[sound_name])

func debug_buses() -> void:
	for i in AudioServer.bus_count:
		print(i, " ", AudioServer.get_bus_name(i))
	print("idx sfx ", _sfx_bus, " bgm ", _bgm_bus)
	print("player sfx ", _sfx.bus, " bgm ", _bgm.bus)
	if _sfx_bus >= 0:
		print("db sfx ", AudioServer.get_bus_volume_db(_sfx_bus))

func set_sfx_volume(linear: float) -> void:
	_set_bus_volume(_sfx_bus, linear)

func get_sfx_volume() -> float:
	return _get_bus_volume(_sfx_bus)

func set_bgm_volume(linear: float) -> void:
	_set_bus_volume(_bgm_bus, linear)

func get_bgm_volume() -> float:
	return _get_bus_volume(_bgm_bus)

func play_bgm(stream: AudioStream, fade := 1.0) -> void:
	if _bgm.stream == stream and _bgm.playing:
		return
	if _bgm_tween:
		_bgm_tween.kill()
	if _bgm.playing and fade > 0.0:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm, "volume_db", -60.0, fade * 0.5)
		_bgm_tween.tween_callback(_swap_bgm.bind(stream))
		_bgm_tween.tween_property(_bgm, "volume_db", 0.0, fade * 0.5)
		return
	_swap_bgm(stream)
	_bgm.volume_db = 0.0

func stop_bgm(fade := 1.0) -> void:
	if _bgm_tween:
		_bgm_tween.kill()
	if fade <= 0.0:
		_bgm.stop()
		return
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm, "volume_db", -60.0, fade)
	_bgm_tween.tween_callback(_bgm.stop)

func _swap_bgm(stream: AudioStream) -> void:
	_bgm.stream = stream
	_bgm.play()

func _set_bus_volume(bus: int, linear: float) -> void:
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(linear, 0.0, 1.0)))
	AudioServer.set_bus_mute(bus, linear <= 0.001)

func _get_bus_volume(bus: int) -> float:
	if bus < 0:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus))

func _hook_tree(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_hook_tree(child)

func _on_node_added(node: Node) -> void:
	if not node is Control:
		return
	var c := node as Control
	if c.is_in_group("no_sfx"):
		return
	var entry := _resolve(c)
	if entry.is_empty():
		return
	if c is BaseButton:
		_hook_button(c as BaseButton, entry)
	elif c is LineEdit:
		_hook_line_edit(c as LineEdit, entry)
	if entry.has("hover") and not c.is_in_group("no_hover"):
		var on_enter := _on_hover.bind(c)
		if not c.mouse_entered.is_connected(on_enter):
			c.mouse_entered.connect(on_enter)

func _hook_button(b: BaseButton, entry: Dictionary) -> void:
	if b is OptionButton or b is MenuButton:
		_hook_dropdown(b, entry)
		return
	if b.toggle_mode:
		var on_toggle := _on_toggled.bind(b)
		if not b.toggled.is_connected(on_toggle):
			b.toggled.connect(on_toggle)
	elif entry.has("pressed"):
		var on_press := play.bind(entry["pressed"])
		if not b.pressed.is_connected(on_press):
			b.pressed.connect(on_press)

func _hook_dropdown(b: BaseButton, entry: Dictionary) -> void:
	if entry.has("pressed"):
		var on_press := play.bind(entry["pressed"])
		if not b.pressed.is_connected(on_press):
			b.pressed.connect(on_press)
	if b is OptionButton:
		var opt := b as OptionButton
		var on_select := _on_item_selected.bind(opt)
		if not opt.item_selected.is_connected(on_select):
			opt.item_selected.connect(on_select)
	var popup := _get_popup(b)
	if popup == null:
		return
	if b is MenuButton and entry.has("select"):
		var on_id := _on_popup_id.bind(entry["select"])
		if not popup.id_pressed.is_connected(on_id):
			popup.id_pressed.connect(on_id)
	if entry.has("hover"):
		var on_focus := _on_popup_focus.bind(entry["hover"])
		if not popup.id_focused.is_connected(on_focus):
			popup.id_focused.connect(on_focus)

func _get_popup(b: BaseButton) -> PopupMenu:
	if b is OptionButton:
		return (b as OptionButton).get_popup()
	if b is MenuButton:
		return (b as MenuButton).get_popup()
	return null

func _hook_line_edit(le: LineEdit, entry: Dictionary) -> void:
	if entry.has("pressed"):
		var on_submit := _on_text_submitted.bind(entry["pressed"])
		if not le.text_submitted.is_connected(on_submit):
			le.text_submitted.connect(on_submit)
	if entry.has("type"):
		var on_typed := _on_text_changed.bind(entry["type"])
		if not le.text_changed.is_connected(on_typed):
			le.text_changed.connect(on_typed)

func _resolve(node: Node) -> Dictionary:
	for group in GROUP_SOUNDS:
		if node.is_in_group(group):
			return GROUP_SOUNDS[group]
	return {}

func _on_toggled(toggled_on: bool, b: BaseButton) -> void:
	if b.button_group and not toggled_on:
		return
	var entry := _resolve(b)
	var key := ""
	if not toggled_on and entry.has("released"):
		key = entry["released"]
	elif entry.has("pressed"):
		key = entry["pressed"]
	if key != "":
		play(key)

func _on_item_selected(_index: int, b: BaseButton) -> void:
	var entry := _resolve(b)
	if entry.has("select"):
		play(entry["select"])
	elif entry.has("pressed"):
		play(entry["pressed"])

func _on_popup_focus(_id: int, key: String) -> void:
	play(key)

func _on_popup_id(_id: int, key: String) -> void:
	play(key)

func _on_text_submitted(_text: String, key: String) -> void:
	play(key)

func _on_text_changed(_text: String, key: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_type < TYPE_COOLDOWN:
		return
	_last_type = now
	play(key)

func _on_hover(c: Control) -> void:
	if c is BaseButton and (c as BaseButton).disabled:
		return
	if c is LineEdit and not (c as LineEdit).editable:
		return
	var entry := _resolve(c)
	if entry.has("hover"):
		play(entry["hover"])