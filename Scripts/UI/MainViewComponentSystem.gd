class_name MainViewComponentSystem
extends Node

@export var news : MV_NewsModule
@export var chat : MV_ChatModule
@export var settings : MV_SettingsModule
@export var profile : MV_ProfileModule
@export var server : MV_ServerModule

@export var header : UIMainviewHeaderButtonSystem

@export var loading : Node
@export var fade_duration : float = 0.15
@export var loading_duration : float = 0.4
var _transitioning : bool = false
var _pending_module : MV_BaseModule = null

var currentWindow : MV_BaseModule

func _init_main_view() -> void:
	news.initState(self)
	chat.initState(self)
	profile.initState(self)
	server.initState(self)
	settings.initState(self)
	
	news.window_panel.hide()
	chat.window_panel.hide()
	profile.window_panel.hide()
	server.window_panel.hide()
	settings.window_panel.hide()
	
	chat.global_message_background.connect(_on_global_message_background)
	header.button_pressed.connect(_on_header_button_pressed)
	header._press_btn("News")
	LauncherController.instance.emulator_opened.connect(_on_game_launched_open)

func _on_header_button_pressed(index : int) -> void:
	_open_specific_window(index)
	return
func _on_global_message_background() -> void:
	header.set_notification(2, true)
	return

func _on_game_launched_open() -> void:
	header._press_btn("Profile")

func _open_private_chat(friendId: int) -> void:
	chat.open_private(friendId)
	header._press_btn("Chat")
	
func _open_profile_user(userId: int) -> void:
	profile.set_target(userId)
	header._press_btn("Profile")


func _open_specific_window(value : int) -> void:
	match value:
		0: 			
			if currentWindow != news:
				_open_new_window(news)
			else:
				_reset_window()
		1: 
			if currentWindow != profile:
				_open_new_window(profile)
			else:
				_reset_window()
		2: _open_new_window(chat)
		3: _open_new_window(settings)
		4: _open_new_window(server)
		_: _open_new_window(news)


func _reset_window() -> void:
	if _transitioning:
		_pending_module = currentWindow
		return
	_open_window(currentWindow)
	



func _open_new_window(module : MV_BaseModule) -> void:
	if _transitioning:
		_pending_module = module
		return
	if module == currentWindow:
		return
	_open_window(module)


func _open_window(module : MV_BaseModule) -> void:
	_transitioning = true

	if currentWindow != null:
		await _fade_out(currentWindow.window_panel)
		currentWindow.window_panel.hide()
		currentWindow.exitState()

	loading.show()
	_show_element(loading)
	await get_tree().create_timer(loading_duration).timeout
	await _fade_out(loading)
	loading.hide()

	currentWindow = module
	currentWindow.window_panel.show()
	currentWindow.startState()
	await _fade_in(currentWindow.window_panel)

	_transitioning = false

	if _pending_module != null and _pending_module != currentWindow:
		var next := _pending_module
		_pending_module = null
		_open_window(next)
	else:
		_pending_module = null
	return

func _fade_out(node : CanvasItem) -> void:
	var t := create_tween()
	t.tween_property(node, "modulate:a", 0.0, fade_duration / 2)
	await t.finished

func _fade_in(node : CanvasItem) -> void:
	node.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(node, "modulate:a", 1.0, fade_duration)
	await t.finished
func _show_element(node : CanvasItem) -> void:
	node.modulate.a = 1.0
	return



			
