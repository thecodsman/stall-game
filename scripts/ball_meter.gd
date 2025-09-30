extends Control

@onready var right : TextureProgressBar = $right
@onready var left : TextureProgressBar = $left


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func set_value(val : float) -> void:
	var tween : Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(right, "value", val, 0.15)
	tween.tween_property(left,  "value", val, 0.15)
	if not is_multiplayer_authority() == false: return
	set_value.rpc(val)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func set_progress_tint(color : Color) -> void:
	right.tint_progress = color
	left.tint_progress = color
	if not is_multiplayer_authority() == false: return
	set_value.rpc(color)
