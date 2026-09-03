class_name ProfileSection
extends Panel

const PADDING := 6.0
const OPEN_MARK := "- "
const CLOSED_MARK := "+ "

@export var title_label : Label
@export var body : Control
@export var scroll : ScrollContainer
@export var content : Control
@export var empty_control : Control
@export var expanded_by_default : bool = true
@export var max_visible_rows : int = 0

var _expanded : bool = true
var _title : String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if title_label:
		_title = title_label.text
	if scroll:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_set_inner_scroll(false)
		scroll.visibility_changed.connect(_refresh_height)
	if content:
		content.minimum_size_changed.connect(_refresh_height)
		if content is Container:
			content.sort_children.connect(_refresh_height)
	if empty_control:
		empty_control.visibility_changed.connect(_refresh_height)
	_expanded = expanded_by_default
	_apply_state()

func reset_state() -> void:
	_expanded = expanded_by_default
	_apply_state()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	_expanded = not _expanded
	AudioController.play("Select-2")
	_apply_state()
	accept_event()

func _apply_state() -> void:
	if body:
		body.visible = _expanded
	if title_label:
		title_label.text = (OPEN_MARK if _expanded else CLOSED_MARK) + _title
	_refresh_height.call_deferred()

func _refresh_height() -> void:
	if body == null or not _expanded:
		return
	var h : float = 0.0
	if scroll and scroll.visible and content:
		h = maxf(h, content.get_combined_minimum_size().y)
	if empty_control and empty_control.visible:
		h = maxf(h, maxf(empty_control.get_combined_minimum_size().y, empty_control.size.y))
	h += PADDING
	var cap := _cap_height()
	var capped : bool = cap > 0.0 and h > cap
	if capped:
		h = cap
	_set_inner_scroll(capped)
	if absf(body.custom_minimum_size.y - h) < 1.0:
		return
	body.custom_minimum_size.y = h

func _set_inner_scroll(enabled: bool) -> void:
	if scroll == null:
		return
	var mode := ScrollContainer.SCROLL_MODE_AUTO if enabled else ScrollContainer.SCROLL_MODE_DISABLED
	if scroll.vertical_scroll_mode != mode:
		scroll.vertical_scroll_mode = mode
	var filter := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if scroll.mouse_filter != filter:
		scroll.mouse_filter = filter

func _cap_height() -> float:
	if max_visible_rows <= 0 or content == null:
		return 0.0
	var row_h : float = 0.0
	var count : int = 0
	for c in content.get_children():
		if c is Control and c.visible:
			row_h = maxf(row_h, (c as Control).get_combined_minimum_size().y)
			count += 1
	if count <= max_visible_rows or row_h <= 0.0:
		return 0.0
	var sep : float = 0.0
	if content is BoxContainer:
		sep = float(content.get_theme_constant("separation"))
	return row_h * float(max_visible_rows) + sep * float(max_visible_rows - 1) + PADDING
