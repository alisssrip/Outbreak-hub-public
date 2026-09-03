class_name PU_Connect_RA_Account
extends BasePopup

@export_category("Login")
@export var login_panel : Control
@export var user_field : LineEdit
@export var psswd_field : LineEdit
@export var send_btn : Button
@export var cancel_btn : Button

var _default_send_text : String = "COMMON_SEND"
var _on_login : Callable

func _setup_popup() -> void:
	send_btn.pressed.connect(_on_send_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	if user_field:
		user_field.text_submitted.connect(_on_field_submitted)
	if psswd_field:
		psswd_field.text_submitted.connect(_on_field_submitted)
	_default_send_text = send_btn.text

func _on_field_submitted(_text: String) -> void:
	if send_btn.disabled:
		return
	_on_send_pressed()

func setup_login(on_login: Callable) -> void:
	_on_login = on_login

func open_popup() -> void:
	super.open_popup()
	_reset_fields()

func _on_send_pressed() -> void:
	if not _on_login.is_valid(): return
	var username = user_field.text if user_field else ""
	var password = psswd_field.text if psswd_field else ""
	_set_loading(true)
	_on_login.call(username, password)

func finish() -> void:
	_set_loading(false)
	_on_login = Callable()
	close_popup()

func _set_loading(loading: bool) -> void:
	send_btn.disabled = loading
	cancel_btn.disabled = loading
	if user_field: user_field.editable = not loading
	if psswd_field: psswd_field.editable = not loading
	send_btn.text = tr("COMMON_SENDING") if loading else _default_send_text

func _reset_fields() -> void:
	if user_field: user_field.clear()
	if psswd_field: psswd_field.clear()
	_set_loading(false)

func _on_cancel_pressed() -> void:
	_on_login = Callable()
	close_popup()

func focus_element() -> void:
	if user_field:
		user_field.grab_focus()