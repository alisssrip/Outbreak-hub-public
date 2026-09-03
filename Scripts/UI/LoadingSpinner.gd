class_name LoadingSpinner
extends TextureRect

@export var rotation_speed : float = 180.0

var _spinning : bool = false

func _ready() -> void:
	start()

func _process(delta: float) -> void:
	if _spinning:
		rotation_degrees += rotation_speed * delta

func start() -> void:
	_spinning = true
	rotation_degrees = 0.0
	show()

func stop() -> void:
	_spinning = false
	hide()