extends Base_State;
class_name Login_State;

@export var login: UI_Hanlder_Login;
@export var loading: UI_Hanlder_Login_Loading
@export var loginContainer : Control
@export var logoSprite : Control

@export var outTransitionTime : float

const LACONCHADELALORA : bool = false

func initState( hndlr : State_Controller) -> Base_State:
	ctx = hndlr;
	return self;

func startState() -> void:
	login.on_login_pressed.connect(_login);
	login.on_Create_Account_Pressed.connect(create_account)
	login.on_Restore_Pass_Pressed.connect(forget_pass)
	_reset_fade()
	loginContainer.show()
	login._show_all();
	return;

func _reset_fade() -> void:
	logoSprite.modulate.a = 1.0
	login.loginControl.modulate.a = 1.0
	loading.lodingControl.modulate.a = 1.0

func updateState() -> void:
	return;

func exitState() -> void:
	login.on_login_pressed.disconnect(_login);
	loginContainer.hide()
	return;

func _login() -> void:
	if await try_login(login.userLoginField.text, login.pswrdLoginField.text) :
		ctx._change_state(ctx.loadingState)
	return

func try_login(user: String, pswd: String) -> bool:
	if LACONCHADELALORA:
		user = "maki"
		pswd = "123854697Alice"
	login._hide_all()
	loading._show_all()
	var result = await NetworkHandler.login.login(user, pswd)
	if result == "":
		await NetworkHandler.sleep(2)
		_exit_animation()
		await NetworkHandler.sleep(outTransitionTime)
		return true

	else:
		var text: String
		match result:
			"credential": 
				text = tr("LOGIN_ERR_CREDENTIALS") 
				await NetworkHandler.sleep(5)
			"connection": 
				text = tr("LOGIN_ERR_CONNECTION")
				await NetworkHandler.sleep(2)
			_: 
				text = tr("LOGIN_ERR_UNKNOWN")
		loading._hide_all()
		login.set_error_nsg(text)
		login._show_all()
		return false

func forget_pass() -> void:
	Popups_Controller.instance.show_confirm(tr("POPUP_OPEN_BROWSER"), func(): OS.shell_open(Endpoints.website() + "/main/#recovery"))
	return;

func create_account() -> void:
	Popups_Controller.instance.show_confirm(tr("POPUP_OPEN_BROWSER"), func(): OS.shell_open(Endpoints.website() + "/main/#register"))
	return;

func _exit_animation() -> void:
	login._hide_all()
	loading._fade_all(false, outTransitionTime, func() -> void: loading._hide_all())
	var tween = create_tween()
	tween.tween_property(logoSprite, "modulate:a", 0.0, outTransitionTime)
	return
