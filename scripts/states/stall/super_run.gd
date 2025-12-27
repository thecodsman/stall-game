extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("run")


func physics_update(delta : float) -> void:
	if player.in_water: player.velocity = player.velocity.lerp(Vector2.ZERO, player.WATER_GROUND_FRICTION * delta)
	if not player.input.direction.x && abs(player.velocity.x) < 20:
		finished.emit("Idle")
	elif sign(player.input.direction.x) == -player.sprite.scale.x:
		finished.emit("Skidding")
	player.move(delta, player.ACCEL, player.SUPER_RUN_SPEED, false)
	player.apply_gravity(delta)
	if not Engine.get_physics_frames() % 6:
		player.spawn_afterimage.rpc()
	if not Engine.get_physics_frames() % 20:
		player.spawn_smoke.rpc(Vector2(-2*player.sprite.scale.x,4))
	if check_for_jump(false): player.jump = player.Jump.SUPER
	check_for_attack()
	check_for_special()
	check_for_super_slide()
