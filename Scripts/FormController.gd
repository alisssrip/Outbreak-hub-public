extends Control

@export_subgroup("Login")
@export var loginControl: Control;
@export var userLoginField: LineEdit;
@export var pswrdLoginField: LineEdit;
@export var sndLoginBtn: Button;

@export_subgroup("SignUp")
@export var signUpControl: Control;
@export var usrSignupField: LineEdit;
@export var emailSignupField: LineEdit;
@export var passSignupField: LineEdit;
@export var confSignupField: LineEdit;
@export var sndSignupBtn: Button;

@export_subgroup("Help")
@export var restorePasswordContainer: Control;
@export var restorePasswordBtn: Button;
@export var createAccountBtn: Button;
@export var alreadyHasAccount: Button;

func _ready() -> void:
	sndLoginBtn.pressed.connect(func(): _showSignUpForm(true));
	sndSignupBtn.pressed.connect(func(): _showSignUpForm(true));
	createAccountBtn.pressed.connect(func(): _showSignUpForm(true));
	alreadyHasAccount.pressed.connect(func(): _showSignUpForm(false));
	restorePasswordBtn.pressed.connect(func(): _restorePassword());
	return;

func _login() -> void:
	return;
func _signup() -> void:
	return;
func _showSignUpForm(value: bool) -> void:
	if(value):
		signUpControl.show();
		loginControl.hide();
	else:
		signUpControl.hide();
		loginControl.show();
	return;
func _restorePassword() -> void:
	loginControl.hide();
	restorePasswordContainer.show();
	return;
