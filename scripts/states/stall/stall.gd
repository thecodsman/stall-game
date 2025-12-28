extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("stall")
	player.set_collision_mask_value(3, false)
	player.is_ball_stalled = (player.ball != null)


func physics_update(delta : float) -> void:
	var anim_finished : bool = (player.anim.current_animation == "")
	player.apply_gravity(delta)
	if not player.is_on_floor(): player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
	else: player.velocity = player.velocity.lerp(Vector2.ZERO, player.FRICTION*delta)
	if anim_finished && not player.is_ball_stalled: finished.emit("Idle")
	if not player.ball && player.is_ball_stalled:
		player.is_ball_stalled = false
		print_debug("poo")
		finished.emit("Idle")
		return
	if not player.ball: return
	if (player.is_ball_stalled && not player.ball.state == player.ball.State.STALLED) || (player.is_ball_stalled && player.ball.staller != player):
		finished.emit("Idle")
		return
	if not player.is_ball_stalled: return
	if not anim_finished: return
	var kick_pressed : bool = player.input.is_joy_button_pressed(JOY_BUTTON_X)
	if kick_pressed: finished.emit("StallKick")


func exit() -> void:
	print("GUH")
	player.set_collision_mask_value(3, true)
	player.is_ball_stalled = false


func _on_stall_box_body_entered(ball : Ball) -> void:
	if ball.server != self && ball.server != null: return
	player.ball = ball
	if player.ball.stalled || not is_multiplayer_authority(): return
	player.stall_ball.rpc(player.ball.get_path())

