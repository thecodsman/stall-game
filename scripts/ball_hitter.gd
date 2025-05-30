extends Area2D

@onready var kick_sfx = $kick_sfx
@onready var collider = $CollisionShape2D

func _on_body_entered(ball:Ball) -> void:
	kick_sfx.play()
	var dir = Vector2(Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(owner.player_index, JOY_AXIS_LEFT_Y))
	if dir.length() < 0.09: dir = Vector2.UP
	apply_ball_ownership.rpc(ball)
	ball.update_color.rpc(owner.self_modulate, owner.player_index)
	kick.rpc(ball,dir)


@rpc("any_peer", "call_local", "reliable")
func kick(ball : Ball, dir : Vector2):
	collider.set_deferred("disabled", true)
	Globals.freeze_frame(0.05)
	var angle_diff : float = (ball.velocity.angle() * sign(dir.angle())) - dir.angle()
	if ball.velocity.length() > 0: ball.spin = (abs(ball.spin) * sign(angle_diff)) + (angle_diff) * clampf(ball.velocity.length() * 0.0145, 0.5, 3)
	ball.velocity = Vector2(ball.velocity.length() + 140,0).rotated(dir.angle())


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball : Ball):
	if ball.owner_index != owner.player_index && ball.owner_level > 0:
		ball.owner_level -= 1
	else:
		ball.owner_index = owner.player_index
		ball.owner_level += 1
		if ball.owner_level > Ball.MaxOwnerLevel: ball.owner_level = Ball.MaxOwnerLevel
