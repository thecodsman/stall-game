class_name HitBox extends Area2D

signal hit

@export var input : PlayerInput
@export var player : Player
@export var direction : Vector2 = Vector2.ZERO
@export var di_power : float = 0.25
@export var ownership_damage : float = 0.25
@export var power : float = 140.0
@export var damage : float = 0.05
@export var hit_stun : int = 4 ## in frames
@export var hit_fx_scene : PackedScene
@onready var kick_sfx : AudioStreamPlayer = $kick_sfx
@onready var collider : CollisionShape2D = $CollisionShape2D
var can_cancel : bool = false
var ball_damage : float :
	get():
		var value : float
		if Globals.camera.ball != null:
			value = Globals.camera.ball.damage
		else:
			value = 1
		return value


func _on_body_entered(obj : Node2D) -> void:
	if obj is Ball:
		handle_ball_collision(obj)
	# elif obj is Player:
	# 	handle_player_collision(obj)


func _on_area_entered(hurtbox : Area2D) -> void:
	if not hurtbox is HurtBox: return
	if hurtbox.owner == owner: return
	const power_mult : float = 2.0
	var dir : Vector2 = Vector2.from_angle(global_position.angle_to_point(hurtbox.owner.global_position))
	var knockback : Vector2 = (power * dir * ball_damage * power_mult) + (power * di_power * input.direction)
	hurtbox.hurt.emit(hit_stun, knockback)
	hit.emit(hurtbox.owner)
	kick_sfx.play()
	var hit_fx : Node2D = hit_fx_scene.instantiate()
	hit_fx.global_position = hurtbox.owner.global_position
	$"/root/stage/SubViewportContainer/game".add_child(hit_fx)


func handle_player_collision(_player : Player) -> void:
	if _player == player: return
	hit.emit(_player)
	if direction == Vector2.ZERO:
		var dir2player : float = global_position.angle_to_point(_player.global_position)
		kick_player.rpc(_player.get_path(), Vector2.from_angle(dir2player))
	else: kick_player.rpc(_player.get_path(), direction * global_scale.rotated(global_rotation))
	

@rpc("authority", "call_local", "reliable")
func kick_player(player_path : NodePath, dir : Vector2) -> void:
	var _player : Player = get_node(player_path)
	const power_mult : float = 2
	_player.velocity += (power * dir * ball_damage * power_mult) + (power * di_power * input.direction)
	kick_sfx.play()
	var hit_fx : Node2D = hit_fx_scene.instantiate()
	hit_fx.global_position = _player.global_position
	$"/root/stage/SubViewportContainer/game".add_child(hit_fx)


func handle_ball_collision(ball : Ball) -> void:
	if ball.server != owner && ball.server != null: return
	ball.server = null
	ball.set_server.rpc(null)
	hit.emit(ball)
	kick_sfx.play()
	var hit_fx : Node2D = hit_fx_scene.instantiate()
	hit_fx.global_position = ball.global_position
	$"/root/stage/SubViewportContainer/game".add_child(hit_fx)
	if not is_multiplayer_authority(): return
	if direction == Vector2.ZERO:
		var dir2ball : float = global_position.angle_to_point((ball.global_position))
		kick_ball.rpc(ball.get_path(), Vector2.from_angle(dir2ball))
	else: kick_ball.rpc(ball.get_path(), direction * global_scale.rotated(global_rotation))


@rpc("authority", "call_local", "reliable")
func kick_ball(ball_path : NodePath, dir : Vector2) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	if dir.length() < input.DeadZone: dir = Vector2.UP
	if Globals.stats.get("hits"): Globals.stats["hits"] += 1
	else: Globals.stats["hits"] = 1
	ball.set_state(ball.State.NORMAL)
	apply_ball_ownership(ball_path)
	can_cancel = true
	if ball.combo_owner != player.player_index and ball.owner_level < ball.OWNER_COMBO_THRESHOLD:
		ball.combo = 1
		ball.combo_owner = player.player_index
		UI.combo_counter.hide()
	elif ball.combo_owner == player.player_index:
		ball.combo += 1
		if ball.combo >= 4: update_combo_counter(ball.combo, player.self_modulate)
	var angle_diff : float = (ball.velocity.angle() * sign(dir.angle())) - dir.angle()
	if ball.velocity.length() > 0:
		const vel_to_spin_mult : float = 0.0145
		const min_vel_to_spin : float = 0.5
		const max_vel_to_spin : float = 3
		ball.spin = (
				(abs(ball.spin) * sign(angle_diff)) +
				angle_diff *
				clampf(
						ball.velocity.length() * vel_to_spin_mult,
						min_vel_to_spin,
						max_vel_to_spin
				)
		)
	var combo_mult : float = ((ball.combo * ball.COMBO_SPEED_MULT) ** 2) + 1
	if ball.combo_owner != player.player_index: combo_mult = 1
	ball.velocity = Vector2((ball.velocity.length() * 0.55) + (power * combo_mult) ,0).rotated(dir.angle()) + (power * di_power * input.direction)
	ball.damage += damage
	UI._on_bal_percent_change(ball.damage)


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball_path : NodePath) -> void :
	var ball : Ball = get_node(ball_path)
	if not ball || Globals.round_ending: return
	if ball.owner_index != player.player_index:
		ball.owner_level -= ownership_damage
		if ball.owner_level < 0:
			ball.owner_index = player.player_index
			ball.owner_level = abs(ball.owner_level)
	else:
		ball.owner_level += ownership_damage
	if ball.owner_level > ball.MAX_OWNER_LEVEL:
		ball.owner_level = ball.MAX_OWNER_LEVEL
	if ball.owner_level < ball.OWNER_SCORE_THRESHOLD:
		ball.scorrable = false
		Globals.score_line.deactivate()
	ball.update_color(player.self_modulate, player.player_index)


@rpc("authority", "call_remote", "reliable", 1)
func update_combo_counter(combo : int, color : Color) -> void:
	if player.player_index % 2 == 0: 
		UI.combo_counter.position = (
				Vector2(
					96 - UI.combo_counter.size.x,
					48 - (UI.combo_counter.size.y / 2)
					)
				+ Vector2(
					randf_range(0,-4),
					randf_range(-4,4)
					)
			)
	else: 
		UI.combo_counter.position = (
				Vector2(
					0,
					48 - (UI.combo_counter.size.y/2)
					)
				+ Vector2(
					randf_range(0,8),
					randf_range(-4,4)
					)
			)
	UI.combo_counter.pivot_offset = UI.combo_counter.size/2
	UI.combo_counter.show()
	UI.combo_counter.text = "%sx\n\nCOMBO" % combo
	UI.combo_counter.material.set_shader_parameter("outline_color", color)
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(UI.combo_counter, "scale", Vector2(1,1), 0.2).from(Vector2(0.5,0.5))
	tween.tween_property(UI.combo_counter, "rotation", randf_range(-PI/10,PI/10), 0.2).from(0)
	if multiplayer.get_remote_sender_id() != 0: return
	update_combo_counter.rpc(combo, color)
