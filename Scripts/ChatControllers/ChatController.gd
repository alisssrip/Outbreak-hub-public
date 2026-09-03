class_name ChatController
extends Node

signal message_sent(text: String)
signal load_more_requested
signal on_global_button_pressed
signal on_view_profile_pressed
signal on_remove_friend_pressed
signal message_user_clicked(user_id: int)

const GROUP_WINDOW_SEC := 300

@export var message_scene : PackedScene
@export var messages_container : VBoxContainer
@export var load_more_button : Button
@export var input_field : LineEdit
@export var send_button : TextureButton
@export var chat_title : Label
@export var global_button : Button
@export var view_profile_button : Button
@export var remove_friend_button : Button
@export var scroll_container : ScrollContainer
@export var main_panel : Panel
@export var show_avatars : bool = false
@export var avatar_placeholder : Texture2D

var _is_loading_more : bool = false
var _last_instance : UserChatMessageSystem = null
var _last_user : int = 0
var _last_time : int = 0
var _more_buffer : Array = []

func _ready() -> void:
	load_more_button.pressed.connect(_on_load_more_pressed)
	input_field.text_submitted.connect(_on_input_submitted)
	send_button.pressed.connect(_on_send_pressed)
	global_button.pressed.connect(_on_global_button_pressed)
	if view_profile_button:
		view_profile_button.pressed.connect(func(): on_view_profile_pressed.emit())
	if remove_friend_button:
		remove_friend_button.pressed.connect(func(): on_remove_friend_pressed.emit())

func set_friend_actions_visible(visible: bool) -> void:
	if view_profile_button:
		view_profile_button.visible = visible
	if remove_friend_button:
		remove_friend_button.visible = visible

func _on_message_received(data: Dictionary) -> void:
	if _is_loading_more:
		_more_buffer.append(data)
		return
	var user_id : int = int(data.get("user_id", 0))
	var ts := _to_unix(str(data.get("timestamp", "")))
	if _can_group(user_id, ts):
		_last_instance.append_message(str(data.get("msg", "")))
		_last_time = ts
		scroll_container.scroll_to_bottom_immediate()
		return
	var instance := _spawn_message(data)
	messages_container.add_child(instance)
	scroll_container.scroll_to_bottom_immediate()
	_last_instance = instance
	_last_user = user_id
	_last_time = ts

func _can_group(user_id: int, ts: int) -> bool:
	if not is_instance_valid(_last_instance):
		return false
	if user_id != _last_user:
		return false
	if ts <= 0 or _last_time <= 0:
		return false
	return ts - _last_time <= GROUP_WINDOW_SEC

func _to_unix(raw: String) -> int:
	if raw.is_empty():
		return 0
	return int(Time.get_unix_time_from_datetime_string(raw.substr(0, 19)))
func _flush_more_buffer() -> void:
	if _more_buffer.is_empty():
		return
	var batch := _more_buffer.duplicate()
	_more_buffer.clear()
	batch.sort_custom(_sort_by_timestamp)
	var instances := _build_grouped_instances(batch)
	await _prepend_instances(instances)

func _sort_by_timestamp(a: Dictionary, b: Dictionary) -> bool:
	return _to_unix(str(a.get("timestamp", ""))) < _to_unix(str(b.get("timestamp", "")))

func _build_grouped_instances(msgs: Array) -> Array:
	var result : Array = []
	var last_inst : UserChatMessageSystem = null
	var last_user : int = 0
	var last_time : int = 0
	for data in msgs:
		var uid : int = int(data.get("user_id", 0))
		var ts := _to_unix(str(data.get("timestamp", "")))
		if last_inst != null and uid == last_user and ts > 0 and last_time > 0 and ts - last_time <= GROUP_WINDOW_SEC:
			last_inst.append_message(str(data.get("msg", "")))
			last_time = ts
			continue
		var inst := _spawn_message(data)
		if inst == null:
			continue
		result.append(inst)
		last_inst = inst
		last_user = uid
		last_time = ts
	return result

func _prepend_instances(instances: Array) -> void:
	if instances.is_empty():
		return
	scroll_container.set_freeze(true)
	var anchor : Control = null
	if messages_container.get_child_count() > 0:
		anchor = messages_container.get_child(0)
	var anchor_top := anchor.position.y if anchor != null else 0.0
	var old_scroll := float(scroll_container.scroll_vertical)
	for i in instances.size():
		var inst : Control = instances[i]
		messages_container.add_child(inst)
		messages_container.move_child(inst, i)
	await messages_container.sort_children
	var shift := (anchor.position.y - anchor_top) if anchor != null else 0.0
	scroll_container.teleport_scroll(old_scroll + shift)
	scroll_container.set_freeze(false)

func set_title(title: String) -> void:
	if chat_title != null:
		chat_title.text = title

func _on_load_more_pressed() -> void:
	load_more_requested.emit()

func _set_panel(show : bool) -> void:
	if show: main_panel.show()
	else: main_panel.hide()

func _on_input_submitted(text: String) -> void:
	_send_message(text)

func _on_send_pressed() -> void:
	if input_field != null:
		_send_message(input_field.text)

func _send_message(text: String) -> void:
	var clean := text.strip_edges()
	if clean.is_empty():
		_return_focus()
		return
	message_sent.emit(clean)
	if input_field != null:
		input_field.clear()
	_return_focus()

func _return_focus() -> void:
	input_field.grab_focus.call_deferred()
	input_field.call_deferred("edit")

func clear_chat() -> void:
	for child in messages_container.get_children():
		child.queue_free()
	_last_instance = null
	_last_user = 0
	_last_time = 0

func show_load_more_button() -> void:
	if load_more_button != null:
		load_more_button.show()

func hide_load_more_button() -> void:
	if load_more_button != null:
		load_more_button.hide()

func _spawn_message(data: Dictionary) -> UserChatMessageSystem:
	var chat_msg := message_scene.instantiate() as UserChatMessageSystem
	if chat_msg == null:
		push_error("instance failed")
		return null

	var user_id : int = int(data.get("user_id", 0))
	chat_msg.set_user_id(user_id)
	chat_msg.user_clicked.connect(_on_message_user_clicked)

	if not show_avatars:
		chat_msg.setup_without_image(data.user_name, data.date, data.msg)
	else:
		var texture := RpcModules.user_store.get_avatar(user_id) if user_id > 0 else null
		if texture != null:
			chat_msg.setup_with_image(data.user_name, data.date, data.msg, texture)
		else:
			chat_msg.setup_with_image(data.user_name, data.date, data.msg, avatar_placeholder)
			if user_id > 0:
				RpcModules.user_store.user_updated.connect(func(uid: int, fields: Array):
					if uid == user_id and is_instance_valid(chat_msg):
						var t := RpcModules.user_store.get_avatar(user_id)
						if t != null:
							chat_msg.set_image(t)
				)
	return chat_msg

static func _format_timestamp(raw: String) -> String:
	var parts = raw.split("T")
	if parts.size() < 2:
		return raw
	var date = parts[0].split("-")
	var time = parts[1].split(":")
	if date.size() < 3 or time.size() < 2:
		return raw
	return "%s:%s %s/%s/%s" % [time[0], time[1], date[2], date[1], date[0]]

func set_loading_more(value: bool) -> void:
	_is_loading_more = value
	if value:
		_more_buffer.clear()
	else:
		_flush_more_buffer()

func _on_global_button_pressed() -> void:
	on_global_button_pressed.emit()

func _on_message_user_clicked(user_id: int) -> void:
	message_user_clicked.emit(user_id)
