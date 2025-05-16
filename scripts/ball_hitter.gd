extends Area2D

@onready var kick_sfx = $kick_sfx

func _on_body_entered(ball:Ball) -> void:
	Globals.freeze_frame(0.05)
	kick_sfx.play()
	var dir = Vector2(Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_Y))
	if dir.length() < 0.09: dir = Vector2.UP
	apply_ball_ownership(ball)
	ball.update_color(owner.modulate, owner.player_index)
	var kick_angle_offset = ball.spin
	if ball.velocity.length() > 0: ball.spin += ((ball.velocity.angle() * sign(dir.angle())) - dir.angle()) * clampf(ball.velocity.length() * 0.01, 0.5, 3)
	ball.velocity += (dir.normalized() * 140).rotated(clampf(kick_angle_offset, -PI/4,PI/4))


func apply_ball_ownership(ball:Ball):
	if ball.owner_index != owner.player_index && ball.owner_level > 0:
		ball.owner_level -= 1
	else:
		ball.owner_index = owner.player_index
		ball.owner_level += 1
		if ball.owner_level > Ball.MaxOwnerLevel: ball.owner_level = Ball.MaxOwnerLevel
