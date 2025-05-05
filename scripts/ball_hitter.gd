extends Area2D


func _on_body_entered(body:Node2D) -> void:
	Globals.freeze_frame(0.15)
	var dir = Vector2(Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_Y))
	if dir.length() < 0.9: dir = Vector2.ZERO
	if dir.length() == 0: dir = Vector2.UP
	body.last_hit = owner.player_index
	body.velocity += dir.normalized() * 140


