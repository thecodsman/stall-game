class_name KickBox extends Area2D

@export var input : PlayerInput
@export var player : Player
@export var direction : Vector2 = Vector2.ZERO
@export var di_power : float = 0.25
@export var power : float = 140.0
@export var damage : float = 0.05
@onready var kick_sfx = $kick_sfx
@onready var collider = $CollisionShape2D


func _on_body_entered(ball:Ball) -> void:
	kick_sfx.play()
	if not is_multiplayer_authority(): return
	if direction == Vector2.ZERO:
		var dir2ball = global_position.angle_to_point((ball.global_position))
		kick.rpc_id(1, ball.get_path(), Vector2.from_angle(dir2ball))
	else: kick.rpc_id(1, ball.get_path(), direction * global_scale.rotated(global_rotation))


@rpc("authority", "call_local", "reliable")
func kick(ball_path : NodePath, dir : Vector2) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	if dir.length() < input.DeadZone: dir = Vector2.UP
	ball.set_state(ball.State.NORMAL)
	collider.set_deferred("disabled", true)
	apply_ball_ownership(ball_path)
	#Globals.freeze_frame(0.05)
	var angle_diff : float = (ball.velocity.angle() * sign(dir.angle())) - dir.angle()
	if ball.velocity.length() > 0: ball.spin = (abs(ball.spin) * sign(angle_diff)) + (angle_diff) * clampf(ball.velocity.length() * 0.0145, 0.5, 3)
	ball.velocity = Vector2(ball.velocity.length() + (power * ball.damage) ,0).rotated(dir.angle()) + (power * di_power * input.direction)
	ball.damage += damage
	UI._on_bal_percent_change(ball.damage)


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball_path : NodePath):
	var ball : Ball = get_node(ball_path)
	if not ball || UI.game_text.visible: return
	if ball.owner_index != player.player_index && ball.owner_level > 0:
		ball.owner_level -= 1
	else:
		ball.owner_index = player.player_index
		ball.owner_level += 1
		if ball.owner_level > Ball.MAX_OWNER_LEVEL: ball.owner_level = Ball.MAX_OWNER_LEVEL
	ball.update_color(player.self_modulate, player.player_index)
