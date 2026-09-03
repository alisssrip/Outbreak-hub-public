extends TextEdit

var _focus_click = false

func _ready() -> void:
	caret_blink = true
	caret_blink_interval = 0.5
	return

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not has_focus():
				_focus_click = true
		else:
			if _focus_click:
				_focus_click = false
				deselect()
				var last = get_line_count() - 1
				set_caret_line(last)
				set_caret_column(get_line(last).length())
				adjust_viewport_to_caret()

