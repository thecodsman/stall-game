extends Area2D

@export var input : PlayerInput
@export var player : Player
@onready var kick_sfx = $kick_sfx
@onready var collider = $CollisionShape2D
var direction : Vector2 = Vector2.ZERO
var power : float = 140.0


func _on_body_entered(ball:Ball) -> void:
	kick_sfx.play()
	if not is_multiplayer_authority(): return
	if direction == Vector2.ZERO: kick.rpc_id(1, ball.get_path(), input.direction)
	else: kick.rpc_id(1, ball.get_path(), direction)


@rpc("authority", "call_local", "reliable")
func kick(ball_path : NodePath, dir : Vector2) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	if dir.length() < input.dead_zone: dir = Vector2.UP
	collider.set_deferred("disabled", true)
	apply_ball_ownership(ball_path)
	#Globals.freeze_frame(0.05)
	var angle_diff : float = (ball.velocity.angle() * sign(dir.angle())) - dir.angle()
	if ball.velocity.length() > 0: ball.spin = (abs(ball.spin) * sign(angle_diff)) + (angle_diff) * clampf(ball.velocity.length() * 0.0145, 0.5, 3)
	ball.velocity = Vector2(ball.velocity.length() + (power * ball.damage) ,0).rotated(dir.angle())
	ball.damage += 0.05


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball_path : NodePath):
	var ball : Ball = get_node(ball_path)
	if not ball || GameText.visible: return
	if ball.owner_index != player.player_index && ball.owner_level > 0:
		ball.owner_level -= 1
	else:
		ball.owner_index = player.player_index
		ball.owner_level += 1
		if ball.owner_level > Ball.MAX_OWNER_LEVEL: ball.owner_level = Ball.MAX_OWNER_LEVEL
	ball.update_color(player.self_modulate, player.player_index)
