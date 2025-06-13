extends Area2D

@export var input : PlayerInput
@export var player : Player
@onready var kick_sfx = $kick_sfx
@onready var collider = $CollisionShape2D


func _on_body_entered(ball:Ball) -> void:
	kick_sfx.play()
	if not is_multiplayer_authority(): return
	rpc_id(1, "kick", ball.get_path())


@rpc("authority", "call_local", "unreliable_ordered")
func kick(ball_path : NodePath) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	var dir = input.direction
	if dir.length() < input.dead_zone: dir = Vector2.UP
	#collider.set_deferred("disabled", true)
	apply_ball_ownership(ball_path)
	#Globals.freeze_frame(0.05)
	var angle_diff : float = (ball.velocity.angle() * sign(dir.angle())) - dir.angle()
	if ball.velocity.length() > 0: ball.spin = (abs(ball.spin) * sign(angle_diff)) + (angle_diff) * clampf(ball.velocity.length() * 0.0145, 0.5, 3)
	ball.velocity = Vector2(ball.velocity.length() + 140,0).rotated(dir.angle())


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball_path : NodePath):
	var ball : Ball = get_node(ball_path)
	if not ball: return
	if ball.owner_index != player.player_index && ball.owner_level > 0:
		ball.owner_level -= 1
	else:
		ball.owner_index = player.player_index
		ball.owner_level += 1
		if ball.owner_level > Ball.MAX_OWNER_LEVEL: ball.owner_level = Ball.MAX_OWNER_LEVEL
	ball.update_color(player.self_modulate, player.player_index)
