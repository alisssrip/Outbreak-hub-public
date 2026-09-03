extends LineEdit

var regex := RegEx.new()
var old_text := ""

func _ready() -> void:
	regex.compile("^[0-9.]*$")
	
	old_text = text
	
	text_changed.connect(_on_text_changed)

func _on_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		old_text = new_text
	else:
		var current_caret_position = caret_column
		text = old_text
		
		caret_column = current_caret_position - 1