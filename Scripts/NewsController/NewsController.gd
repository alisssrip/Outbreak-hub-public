class_name NewsController
extends Node

signal load_more_requested

@export var article_prefab: PackedScene
@export var articles_container: Node
@export var load_more_button: Button

func _ready() -> void:
	if load_more_button:
		load_more_button.pressed.connect(_on_load_more_pressed)

func set_news(data: Array[ArticleData]) -> void:
	_clear_articles()
	_add_articles(data)

func append_news(data: Array[ArticleData]) -> void:
	_add_articles(data)
	set_load_more_enabled(true)

func set_load_more_enabled(enabled: bool) -> void:
	if load_more_button:
		load_more_button.disabled = not enabled

func set_load_more_visible(visible: bool) -> void:
	if load_more_button:
		load_more_button.visible = visible

func _add_articles(data: Array[ArticleData]) -> void:
	for item in data:
		var article: ArticleSystem = article_prefab.instantiate()
		articles_container.add_child(article)
		article._set_article(item.title, item.description, item.sprite)
	if load_more_button and load_more_button.get_parent() == articles_container:
		articles_container.move_child(load_more_button, -1)

func _clear_articles() -> void:
	for child in articles_container.get_children():
		if child is ArticleSystem:
			child.queue_free()

func _on_load_more_pressed() -> void:
	set_load_more_enabled(false)
	load_more_requested.emit()
