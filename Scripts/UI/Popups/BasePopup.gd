class_name BasePopup
extends Node

signal closed

const WIDTH_PADDING := 40.0

var open : bool

@export var main_panel : Control
@export var min_width : float = 300.0

func _ready() -> void:
	close_popup()
	_setup_popup()

func _setup_popup() -> void:
	pass

func open_popup() -> void:
	if main_panel:
		open = true
		main_panel.show()
		get_viewport().gui_release_focus()

func close_popup() -> void:
	if main_panel:
		open = false
		main_panel.hide()
	closed.emit()

func fit_width_to_text(label: Control, text: String) -> void:
	if label == null:
		return
	var pad := _ensure_padding(label)
	label.custom_minimum_size.x = clampf(_text_width(label, text) + pad, min_width, min_width * 2.0)
	_recenter.call_deferred()

func _ensure_padding(label: Control) -> float:
	var sb : StyleBox = label.get_theme_stylebox("normal")
	var pad : float = 0.0 if sb == null else sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
	if pad >= WIDTH_PADDING:
		return pad
	var box := StyleBoxEmpty.new()
	box.content_margin_left = WIDTH_PADDING * 0.5
	box.content_margin_right = WIDTH_PADDING * 0.5
	box.content_margin_top = 0.0 if sb == null else sb.get_margin(SIDE_TOP)
	box.content_margin_bottom = 0.0 if sb == null else sb.get_margin(SIDE_BOTTOM)
	label.add_theme_stylebox_override("normal", box)
	return WIDTH_PADDING

func _text_width(label: Control, text: String) -> float:
	var font : Font = label.get_theme_font("font") if label is Label else label.get_theme_font("normal_font")
	var font_size : int = label.get_theme_font_size("font_size") if label is Label else label.get_theme_font_size("normal_font_size")
	if font == null:
		return 0.0
	var widest := 0.0
	for line in text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return widest

func _recenter() -> void:
	if main_panel == null:
		return
	await get_tree().process_frame
	var w : float = maxf(main_panel.get_combined_minimum_size().x, min_width)
	main_panel.offset_left = -w * 0.5
	main_panel.offset_right = w * 0.5
func focus_element() -> void:
	pass