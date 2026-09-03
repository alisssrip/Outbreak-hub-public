extends Node

signal on_resolution_changed(index: int)

const BASE_SIZE := Vector2i(1280, 720)
const SCREEN_FRACTION := 0.82
const MIN_SIZE := Vector2i(960, 540)
const MAX_SCALE := 3

const TEST_SCREENS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

var _test_index := -1

func _ready() -> void:
	_apply_adaptive_window()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_KP_ADD or event.keycode == KEY_EQUAL:
			_cycle_test_screen(1)
		elif event.keycode == KEY_KP_SUBTRACT or event.keycode == KEY_MINUS:
			_cycle_test_screen(-1)
		elif event.keycode == KEY_0:
			_test_index = -1
			_apply_adaptive_window()
		SettingsManager.settings.resolution = _test_index

func _cycle_test_screen(dir: int) -> void:
	var next := clampi(_test_index + dir, 0, TEST_SCREENS.size() - 1)
	if next == _test_index:
		return
	_test_index = next
	Log.d(TEST_SCREENS[_test_index])
	_apply_adaptive_window(TEST_SCREENS[_test_index])

func _set_specific_res(index: int) -> void:
	if index < 0 or index >= TEST_SCREENS.size():
		return
	_test_index = index
	_apply_adaptive_window(TEST_SCREENS[_test_index])

func _apply_adaptive_window(forced_screen := Vector2i.ZERO) -> void:
	var win := get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = BASE_SIZE
	win.min_size = MIN_SIZE
	var screen := forced_screen if forced_screen != Vector2i.ZERO else DisplayServer.screen_get_size(win.current_screen)
	var usable := Vector2(screen) * SCREEN_FRACTION
	var fit_scale := minf(usable.x / BASE_SIZE.x, usable.y / BASE_SIZE.y)
	var min_scale := minf(float(MIN_SIZE.x) / BASE_SIZE.x, float(MIN_SIZE.y) / BASE_SIZE.y)
	var scale := clampf(fit_scale, min_scale, MAX_SCALE)
	var target := Vector2i(int(BASE_SIZE.x * scale), int(BASE_SIZE.y * scale))
	target.x = clampi(target.x, MIN_SIZE.x, screen.x)
	target.y = clampi(target.y, MIN_SIZE.y, screen.y)
	win.size = target
	win.move_to_center()
	on_resolution_changed.emit(_test_index)
	Log.d("sim screen ", screen, " -> window ", target, " scale ", snappedf(scale, 0.01))