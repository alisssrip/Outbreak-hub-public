class_name PU_Progress_Message
extends BasePopup

var _on_cancel: Callable

@export var title_label : Label
@export var cancel_bton : Button
@export var progress_bar : ProgressBar

func _ready() -> void:
	cancel_bton.pressed.connect(_on_cancel_btn_pressed)

func _setup_popup() -> void:
	return

func setup_progress(message: String, onCancel: Callable) -> void:
	if title_label: title_label.text = message
	set_progress(0.0)
	_on_cancel = onCancel

func set_progress(percent: float) -> void:
	if progress_bar: progress_bar.value = percent

func _on_cancel_btn_pressed() -> void:
	if _on_cancel == null: return
	_on_cancel.call()
	close_popup()
	_on_cancel = Callable()
	return
func focus_element() -> void:
	cancel_bton.grab_focus()
	pass
