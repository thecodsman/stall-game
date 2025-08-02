extends Node2D

@onready var lines = $lines

func _ready() -> void:
	for i in range(lines.get_child_count()):
		var child = lines.get_child(i)
		child.rotation = randf_range(-PI,PI)
