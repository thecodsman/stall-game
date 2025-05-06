extends Area2D


func _on_body_entered(ball:Ball) -> void:
	Globals.freeze_frame(0.05)
	var dir = Vector2(Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_Y))
	if dir.length() < 0.9: dir = Vector2.ZERO
	if dir.length() == 0: dir = Vector2.UP
	ball.last_hit = owner.player_index
	ball.velocity += (dir.normalized() * 140).rotated(clampf(ball.spin, -PI/2,PI/2))
	ball.spin += (ball.velocity.angle() - dir.angle())
