extends Control

@onready var right : TextureProgressBar = $right
@onready var left : TextureProgressBar = $left


func set_value(val : float) -> void:
	var tween : Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(right, "value", val, 0.15)
	tween.tween_property(left, "value", val, 0.15)


func set_progress_tint(color : Color) -> void:
	right.tint_progress = color
	left.tint_progress = color
