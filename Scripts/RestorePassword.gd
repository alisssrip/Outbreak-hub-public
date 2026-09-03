extends Control
@export_category("Config")
@export var waitTime: int;

@export_category("Email")
@export var emailContainer: Control;
@export var emailField: LineEdit;
@export var validateMailBtn: Button;

@export_category("Code")
@export var codeContainer: Control;
@export var codeField: LineEdit;
@export var validateCodeBtn: Button;
@export var reSendCodeBtn: Button;

func _ready() -> void:
	validateMailBtn.pressed.connect(func(): _validateMail());
	validateCodeBtn.pressed.connect(func(): _validateCode());
	reSendCodeBtn.pressed.connect(func(): _reSendCode());
	codeContainer.visibility_changed.connect(func(): _startWaitTime());
	return;

func _validateMail() -> void:
	emailContainer.hide();
	codeContainer.show();
	return;
func _validateCode() -> void:
	return;
func _reSendCode() -> void:
	_startWaitTime();
	return;
func _startWaitTime() -> void:
	var x = 0;
	reSendCodeBtn.disabled = true;
	while x < waitTime:
		reSendCodeBtn.text = tr("COMMON_RESEND_WAIT") % (waitTime - x);
		await get_tree().create_timer(1).timeout
		x+=1;
	reSendCodeBtn.text = tr("COMMON_RESEND");
	reSendCodeBtn.disabled = false;
	return;
