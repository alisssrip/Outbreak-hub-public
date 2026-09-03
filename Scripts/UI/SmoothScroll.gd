extends ScrollContainer
class_name SmoothScroll

var target_scroll : float = 0.0
@export var smooth_speed : float = 10.0
@export var scroll_amount : float = 100.0
@export var scrollToBottom : bool
var _freeze : bool = false
var _pinning : bool = false
var _self_scroll : bool = false
var _parent_scroll : SmoothScroll = null
var _parent_scroll_cached : bool = false

func _ready() -> void:
    target_scroll = float(scroll_vertical)
    var vbar = get_v_scroll_bar()
    vbar.value_changed.connect(_on_scroll_bar_value_changed)
    vbar.gui_input.connect(_on_v_scroll_bar_gui_input)
    if scrollToBottom:
        vbar.changed.connect(_on_scroll_bar_changed)

func resetScroll() -> void:
    _pinning = false
    target_scroll = 0.0
    _self_scroll = true
    scroll_vertical = 0
    _self_scroll = false

func _get_max_scroll() -> float:
    var vbar = get_v_scroll_bar()
    return float(vbar.max_value + 20 - vbar.page)

func scroll_to_bottom_immediate() -> void:
    _pinning = true
    _scroll_to_bottom.call_deferred()

func _process(delta: float) -> void:
    if _freeze:
        return
    target_scroll = clamp(target_scroll, 0.0, _get_max_scroll())
    var next = lerp(float(scroll_vertical), target_scroll, smooth_speed * delta)
    if abs(target_scroll - next) < 0.5:
        next = target_scroll
    _self_scroll = true
    scroll_vertical = int(round(next))
    _self_scroll = false

func _gui_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.pressed):
        return
    var dir : float = 0.0
    if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
        dir = 1.0
    elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
        dir = -1.0
    else:
        return
    if _can_scroll(dir):
        scroll_by(dir * scroll_amount)
    else:
        var outer := _get_parent_scroll()
        if outer:
            outer.scroll_by(dir * outer.scroll_amount)
    accept_event()

func _can_scroll(dir: float) -> bool:
    var vbar = get_v_scroll_bar()
    var usable : float = vbar.max_value - vbar.page
    if usable <= 0.0:
        return false
    if dir > 0.0:
        return target_scroll < usable - 0.5
    return target_scroll > 0.5

func scroll_by(amount: float) -> void:
    target_scroll = clamp(target_scroll + amount, 0.0, _get_max_scroll())

func _get_parent_scroll() -> SmoothScroll:
    if _parent_scroll_cached:
        return _parent_scroll
    _parent_scroll_cached = true
    var node : Node = get_parent()
    while node:
        if node is SmoothScroll:
            _parent_scroll = node
            break
        node = node.get_parent()
    return _parent_scroll

func _on_v_scroll_bar_gui_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
        return
    var vbar = get_v_scroll_bar()
    var span = vbar.max_value - vbar.min_value
    if span <= 0.0:
        return
    var grab_pos = (vbar.value - vbar.min_value) / span * vbar.size.y
    var grab_len = vbar.page / span * vbar.size.y
    var my = event.position.y
    if my >= grab_pos and my <= grab_pos + grab_len:
        return
    var usable = span - vbar.page
    var travel = max(vbar.size.y - grab_len, 1.0)
    var ratio = clamp((my - grab_len * 0.5) / travel, 0.0, 1.0)
    target_scroll = ratio * usable
    _pinning = false
    accept_event()

func _on_scroll_bar_changed() -> void:
    if _freeze:
        return
    if _pinning:
        _scroll_to_bottom.call_deferred()

func _on_scroll_bar_value_changed(_x: float) -> void:
    if _freeze:
        return
    if not _self_scroll:
        target_scroll = float(scroll_vertical)
    if scrollToBottom:
        _pinning = (scroll_vertical >= get_v_scroll_bar().max_value - get_v_scroll_bar().page - 1.0)

func _scroll_to_bottom() -> void:
    target_scroll = _get_max_scroll()

func set_target_scroll(value: float) -> void:
    target_scroll = value

func teleport_scroll(value: float) -> void:
    target_scroll = clamp(value, 0.0, _get_max_scroll())
    scroll_vertical = int(target_scroll)

func set_freeze(value: bool) -> void:
    _freeze = value