extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	if player.anim.current_animation == "idle": player.anim.play("fall")
	match player.jump:
		player.Jump.ULTRA:
			player.trail.start()


func physics_update(delta : float) -> void:
	check_for_drop_through()
	check_for_attack()
	check_for_dash()
	check_for_jump()
	check_for_special()
	check_for_fastfall()
	player.apply_gravity(delta)
	if player.in_water:
		player.jumps = 1
		player.dashes = 1
	match player.jump:
		player.Jump.NORMAL:
			if player.input.direction.x: player.move(delta, player.air_accel, player.air_speed, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
		player.Jump.SUPER:
			if player.input.direction.x: player.move(delta, player.air_accel, player.air_speed, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
			if not Engine.get_physics_frames() % 12: player.spawn_afterimage.rpc()
		player.Jump.HYPER:
			if player.input.direction.x: player.move(delta, player.air_accel, player.air_speed, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
			if not Engine.get_physics_frames() % 3: player.spawn_afterimage.rpc()
	if player.velocity.y > 0 && player.anim.current_animation == "": player.anim.play("fall")
	if player.is_on_floor() && player.velocity.y >= 0:
		player.spawn_smoke.rpc(Vector2(0,4))
		finished.emit("Landing")
	elif player.is_on_wall_only() && sign(player.velocity.x) == -player.get_slide_collision(0).get_normal().x:
		finished.emit("Wall")


func exit() -> void:
	player.trail.stop()
