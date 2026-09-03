class_name Popups_Controller
extends Node

static var instance : Popups_Controller

@export_category("Popup Prefabs")
@export var background : Control
@export var accept_cancel_scene : PU_Accept_Cancel_Message
@export var ra_login_scene : PU_Connect_RA_Account
@export var error_scene : PU_Error_Message
@export var progress_scene : PU_Progress_Message
@export var spinner_scene : PU_Spinner_Message

var popup_container : Control

func _ready() -> void:
	instance = self
	accept_cancel_scene.closed.connect(_hide_bg_ALPEDO_ODIOESTEMETODO)
	ra_login_scene.closed.connect(_hide_bg_ALPEDO_ODIOESTEMETODO)
	error_scene.closed.connect(_hide_bg_ALPEDO_ODIOESTEMETODO)
	progress_scene.closed.connect(_hide_bg_ALPEDO_ODIOESTEMETODO)
	spinner_scene.closed.connect(_hide_bg_ALPEDO_ODIOESTEMETODO)

func register_container(container: Control) -> void:
	popup_container = container

func show_confirm(message: String, on_accept: Callable, has_cancel : bool = true, on_cancel: Callable = func(): pass) -> void:
	if not accept_cancel_scene: return
	background.show()
	accept_cancel_scene.setup_message(message, on_accept, on_cancel)
	accept_cancel_scene.open_popup()
	accept_cancel_scene._set_cancel(has_cancel)

func show_error(title: String, error_msg: String, on_closed: Callable = Callable()) -> void:
	if not error_scene: return
	background.show()
	error_scene.setup_error(title, error_msg)
	error_scene.open_popup()
	if on_closed.is_valid():
		error_scene.closed.connect(on_closed, CONNECT_ONE_SHOT)

func show_connect_ra(on_login_request: Callable) -> PU_Connect_RA_Account:
	if not ra_login_scene: return null
	background.show()
	ra_login_scene.setup_login(on_login_request)
	ra_login_scene.open_popup()
	return ra_login_scene

func show_spinner(message: String) -> PU_Spinner_Message:
	if not spinner_scene: return null
	background.show()
	spinner_scene.setup_spinner(message)
	spinner_scene.open_popup()
	return spinner_scene


func show_progress(message: String, on_cancel: Callable) -> PU_Progress_Message:
	if not progress_scene: return null
	background.show()
	progress_scene.setup_progress(message, on_cancel)
	progress_scene.open_popup()
	background.show()
	return progress_scene

func _there_is_popup_open() -> bool:
	if (accept_cancel_scene.open == true 
	or ra_login_scene.open == true 
	or error_scene.open == true 
	or progress_scene.open == true 
	or spinner_scene.open == true):
		return true
	else: return false


func _hide_bg_ALPEDO_ODIOESTEMETODO() -> void:
	if _there_is_popup_open(): return
	background.hide()
	return
