extends Area2D

@export var input : PlayerInput
@onready var kick_sfx = $kick_sfx
@onready var collider = $CollisionShape2D


func _on_body_entered(ball:Ball) -> void:
	kick_sfx.play()
	var dir = input.direction
	if dir.length() < input.dead_zone: dir = Vector2.UP
	apply_ball_ownership.rpc_id(1, ball)
	ball.update_color.rpc_id(1, owner.self_modulate, owner.player_index)
	kick.rpc_id(1,ball,dir)


@rpc("any_peer", "call_local", "reliable")
func kick(ball : Ball, dir : Vector2) -> void:
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
