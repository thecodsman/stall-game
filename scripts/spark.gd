extends Node2D

func _ready() -> void:
	rotation = randf_range(-PI,PI)
	var tween : Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	var rand_scale : float = randf_range(0.6,1)
	tween.tween_property(self, "scale", Vector2(rand_scale,rand_scale), randf_range(0.1,0.2))
	tween.set_parallel()
	tween.tween_property(self, "rotation", randf_range(-PI,PI), randf_range(0.1,0.2))
	#tween.tween_property(self, "position", position + Vector2(randf_range(-4,4),randf_range(-4,4)), randf_range(0.2,0.4))
	tween.set_parallel(false)
	tween.tween_property(self, "scale", Vector2.ZERO, randf_range(0.1,0.2))
	tween.tween_callback(queue_free)
