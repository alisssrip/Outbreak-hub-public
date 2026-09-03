
class_name ArticleSystem
extends PanelContainer

@export var article_image : TextureRect
@export var article_title : Label
@export var article_description : RichTextLabel

func _set_article(title: String, description: String, sprite : Texture2D) -> void:
	article_image.texture = sprite
	article_title.text = title
	article_description.text = description
	return
