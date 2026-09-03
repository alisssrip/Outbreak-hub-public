extends UI_Hanlder
class_name UI_Hanlder_Loading



@export var mainPanel : Control
@export_category("Animation References")
@export var layerMask : Control
@export var lineSprite : Control;
@export var loadingBar: Control
@export var blackOver : ColorRect
@export var video : Control;

@export_subgroup("Animation values")
@export var rotation_speed : float
@export var fromXScaleLayerMask : float
@export var fromPositionLine : Vector2
@export var toXScaleLayerMask : float
@export var toXPositionLine : Vector2

@export_subgroup("Animation times")
@export var loginTransitionTime : float
@export var transitionTime : float

var _current_rotation : float = 0.0
var loadingMaterial: Material

signal on_login_pressed;

func _ready() -> void:
	loadingMaterial = loadingBar.material

func _show_all() -> void:
	mainPanel.show()
	return;
	
func _hide_all() -> void:
	mainPanel.hide()
	return;

func _process(delta: float) -> void:
	_current_rotation = fmod(_current_rotation + rotation_speed * delta, 360.0)
	loadingMaterial.set_shader_parameter("rotation_deg", _current_rotation)

func _fullLoadScreenLoginTransition():
	video.show()
	layerMask.size = Vector2(fromXScaleLayerMask, layerMask.size.y)
	lineSprite.position = fromPositionLine
	blackOver.color = Color(0.0, 0.0, 0.0, 0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(blackOver, "color",Color(0.0, 0.0, 0.0, 0.38), loginTransitionTime /2 )
	tween.tween_property(layerMask, "size:x", toXScaleLayerMask, loginTransitionTime)\
	 .set_trans(Tween.TRANS_SINE).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(lineSprite, "position", toXPositionLine, loginTransitionTime)\
	 .set_trans(Tween.TRANS_SINE).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	return

func _fullLoadScreenTransition(fadeIn : bool):
	video.hide()
	var tween = create_tween()
	mainPanel.modulate.a = 0 if fadeIn else 1;
	tween.tween_property(mainPanel, "modulate:a", 1 if fadeIn else 0, transitionTime / 3)
	return

func _findObject(element: String) -> Control:
	var node = find_child(element, true, false)
	return node if node is Control else null

func _fade_all(fadeIn : bool, time : float, oncomplete: Callable) -> void:return;
func _fade_element(element: String, fadeIn: bool, time: float, oncomplete: Callable) -> void: return;
