class_name MV_NewsModule
extends MV_BaseModule

@export var controller : NewsController

func _ready() -> void:
	controller.load_more_requested.connect(_on_load_more)

func startState() -> void:
	_open_window()
	controller.set_load_more_visible(false)
	controller.set_news([])
	NetworkHandler.news.fetch(func(data: Array[ArticleData], has_more: bool):
		controller.set_news(data)
		controller.set_load_more_visible(has_more)
		for item in data:
			NetworkHandler.news.load_image_for(item, func(texture: Texture2D):
				item.sprite = texture
			)
	)

func updateState() -> void:
	return

func exitState() -> void:
	_close_window()

func _open_window() -> void:
	window_panel.show()

func _close_window() -> void:
	window_panel.hide()

func _on_load_more() -> void:
	NetworkHandler.news.load_more(func(data: Array[ArticleData], has_more: bool):
		controller.append_news(data)
		controller.set_load_more_visible(has_more)
		controller.set_load_more_enabled(has_more)
)
