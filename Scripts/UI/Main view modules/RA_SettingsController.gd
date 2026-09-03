class_name RA_SettingsController
extends Control

@export var hard_mode_toggle : CheckButton
@export var connect_button : Button
@export var nickname_field : LineEdit

var _active_popup : PU_Connect_RA_Account
var _checking : bool = false

func _ready() -> void:
	if hard_mode_toggle:
		hard_mode_toggle.toggled.connect(_on_hard_mode_toggled)
	if connect_button:
		connect_button.pressed.connect(_on_connect_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_load_from_settings()
	_refresh_link_state()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_refresh_link_state()

func _load_from_settings() -> void:
	var s := SettingsManager.settings
	if hard_mode_toggle:
		hard_mode_toggle.button_pressed = s.enable_hard_mode == 1
	if nickname_field:
		nickname_field.text = s.ra_nickname

func _refresh_link_state() -> void:
	if _checking:
		return
	_checking = true
	if connect_button:
		connect_button.disabled = true
		connect_button.text = tr("RA_CHECKING")
	Pcsx2Manager.achievements.verify(func(ok):
		_checking = false
		_apply_link_state(ok)
	)

func _apply_link_state(linked: bool) -> void:
	if connect_button:
		connect_button.disabled = false
		connect_button.text = tr("RA_DISCONNECT") if linked else tr("RA_CONNECT")
	if hard_mode_toggle:
		hard_mode_toggle.disabled = not linked
	if nickname_field:
		nickname_field.text = SettingsManager.settings.ra_nickname if linked else ""

func _on_hard_mode_toggled(pressed: bool) -> void:
	SettingsManager.settings.enable_hard_mode = 1 if pressed else 0
	SettingsManager.save_settings()
	Pcsx2Manager.achievements.set_hardcore(pressed)

func _on_connect_pressed() -> void:
	if Pcsx2Manager.achievements.is_linked:
		Popups_Controller.instance.show_confirm(
			tr("RA_DISCONNECT_CONFIRM"),
			_do_disconnect
		)
		return
	var popup := Popups_Controller.instance.show_connect_ra(_on_login_requested)
	if popup == null:
		return
	_active_popup = popup

func _do_disconnect() -> void:
	Pcsx2Manager.achievements.disconnect_account()
	NetworkHandler.profile.set_ra_username(RpcModules.user.user_id, "", func(_r): pass)
	if hard_mode_toggle:
		hard_mode_toggle.button_pressed = false
	_apply_link_state(false)

func _on_login_requested(username: String, password: String) -> void:
	NetworkHandler.ra.login(username, password, func(result):
		if result == null:
			Popups_Controller.instance.show_error(tr("RA_TITLE"), tr("RA_LOGIN_FAILED"))
			if _active_popup:
				_active_popup.finish()
			return
		var token : String = result.get("token", "")
		var nickname : String = result.get("user", "")
		var s := SettingsManager.settings
		s.ra_nickname = nickname
		s.ra_token = token
		s.enable_ra = 1
		SettingsManager.save_settings()
		if not Pcsx2Manager.achievements.reapply_credentials():
			Popups_Controller.instance.show_error(tr("RA_TITLE"), tr("RA_CONFIG_WRITE_FAILED"))
			if _active_popup:
				_active_popup.finish()
			return
		Pcsx2Manager.achievements.is_linked = true
		NetworkHandler.profile.set_ra_username(RpcModules.user.user_id, nickname, func(_r): pass)
		_apply_link_state(true)
		if _active_popup:
			_active_popup.finish()
	)
