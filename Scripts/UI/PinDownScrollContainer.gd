class_name PinDownScrollContainer
extends ScrollContainer

var _pinning : bool = false

func _init() -> void:
	get_v_scroll_bar().changed.connect(_on_scroll_bar_changed)
	get_v_scroll_bar().value_changed.connect(_on_scroll_bar_value_changed)

func _on_scroll_bar_changed() -> void:
	if _pinning:
		_scroll_to_bottom.call_deferred()

func _on_scroll_bar_value_changed(x: float) -> void:
	_pinning = (scroll_vertical >= get_v_scroll_bar().max_value - get_v_scroll_bar().page - 1.0)

func _scroll_to_bottom() -> void:
	scroll_vertical = get_v_scroll_bar().max_value