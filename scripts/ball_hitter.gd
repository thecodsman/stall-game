class_name KickBox extends Area2D

signal hit

@export var input : PlayerInput
@export var player : Player
@export var direction : Vector2 = Vector2.ZERO
@export var di_power : float = 0.25
@export var power : float = 140.0
@export var damage : float = 0.05
@export var hit_fx_scene : PackedScene
@onready var kick_sfx : AudioStreamPlayer = $kick_sfx
@onready var collider : CollisionShape2D = $CollisionShape2D


func _on_body_entered(ball:Ball) -> void:
	hit.emit(ball)
	kick_sfx.play()
	var hit_fx : Node2D = hit_fx_scene.instantiate()
	hit_fx.global_position = ball.global_position
	$"/root/stage/SubViewportContainer/game".add_child(hit_fx)
	if not is_multiplayer_authority(): return
	if direction == Vector2.ZERO:
		var dir2ball : float = global_position.angle_to_point((ball.global_position))
		kick.rpc_id(1, ball.get_path(), Vector2.from_angle(dir2ball))
	else: kick.rpc_id(1, ball.get_path(), direction * global_scale.rotated(global_rotation))


@rpc("authority", "call_local", "reliable")
func kick(ball_path : NodePath, dir : Vector2) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	if dir.length() < input.DeadZone: dir = Vector2.UP
	if Globals.stats.get("hits"): Globals.stats["hits"] += 1
	else: Globals.stats["hits"] = 1
	ball.set_state(ball.State.NORMAL)
	collider.set_deferred("disabled", true)
	apply_ball_ownership(ball_path)
	var angle_diff : float = (ball.velocity.angle() * sign(dir.angle())) - dir.angle()
	if ball.velocity.length() > 0: ball.spin = ((abs(ball.spin) * sign(angle_diff)) + (angle_diff) * clampf(ball.velocity.length() * 0.0145, 0.5, 3))
	ball.velocity = Vector2((ball.velocity.length() * 0.55) + (power * ball.damage) ,0).rotated(dir.angle()) + (power * di_power * input.direction)
	ball.damage += damage
	UI._on_bal_percent_change(ball.damage)


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball_path : NodePath) -> void :
	var ball : Ball = get_node(ball_path)
	if not ball || Globals.round_ending: return
	if ball.owner_index != player.player_index && ball.owner_level > 0:
		ball.owner_level -= 1
		ball.scorrable = false
		Globals.score_line.deactivate()
	else:
		ball.owner_index = player.player_index
		ball.owner_level += 1
		if ball.owner_level > Ball.MAX_OWNER_LEVEL:
			ball.owner_level = Ball.MAX_OWNER_LEVEL
			return
		ball.scorrable = false
		Globals.score_line.deactivate()
	ball.update_color(player.self_modulate, player.player_index)
