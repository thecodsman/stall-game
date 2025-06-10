extends Label

@onready var shadow = $shadow


func _on_visibility_changed() -> void:
	shadow.text = text

