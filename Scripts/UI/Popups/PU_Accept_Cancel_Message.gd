class_name PU_Accept_Cancel_Message
extends BasePopup

@export var message : Label
@export var accept_btn : Button
@export var cancel_btn : Button

var _on_accept : Callable
var _on_cancel : Callable

func _setup_popup() -> void:
	if accept_btn:
		accept_btn.pressed.connect(_on_accept_pressed)
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel_pressed)

func _set_cancel(active: bool) -> void:
	if active: cancel_btn.show()
	else: cancel_btn.hide()

func setup_message(text: String, on_accept: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	if message:
		message.text = text
		fit_width_to_text(message, text)
	_on_accept = on_accept
	_on_cancel = on_cancel

func _on_accept_pressed() -> void:
	var cb := _on_accept
	_clear_callbacks()
	close_popup()
	if cb.is_valid(): cb.call()

func _on_cancel_pressed() -> void:
	var cb := _on_cancel
	_clear_callbacks()
	close_popup()
	if cb.is_valid(): cb.call()

func _clear_callbacks() -> void:
	_on_accept = Callable()
	_on_cancel = Callable()

func focus_element() -> void:
	accept_btn.grab_focus()
