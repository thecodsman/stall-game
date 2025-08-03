extends Node2D

func _ready():
	rotation = randf_range(-PI,PI)
	var tween : Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	var rand_scale = randf_range(0.6,1)
	tween.tween_property(self, "scale", Vector2(rand_scale,rand_scale), randf_range(0.1,0.2))
	tween.set_parallel()
	tween.tween_property(self, "rotation", randf_range(-PI,PI), randf_range(0.1,0.2))
	tween.set_parallel(false)
	tween.tween_property(self, "scale", Vector2.ZERO, randf_range(0.05,0.1))
	tween.tween_callback(queue_free)
