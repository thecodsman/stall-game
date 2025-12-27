extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("run")
		

func physics_update(delta : float) -> void:
	player.direction = player.input.direction.x
	if player.in_water: player.velocity = player.velocity.lerp(Vector2.ZERO, player.WATER_GROUND_FRICTION * delta)
	if not player.direction && abs(player.velocity.x) < 10: finished.emit("Idle")
	elif not player.direction:
		player.velocity = player.velocity.lerp(Vector2.ZERO, player.FRICTION * delta)
	elif sign(player.direction) == -player.sprite.scale.x: 
		finished.emit("TurnAround")
	elif player.anim.current_animation == "":
		player.anim.play("run")
		player.move(delta, player.ACCEL, player.RUN_SPEED, false)
	elif player.anim.current_animation == "run":
		player.move(delta, player.ACCEL, player.RUN_SPEED, false)
	if not player.is_on_floor():
		await get_tree().create_timer(player.COYOTE_TIME).timeout
		finished.emit("Air")
	else:
		player.dashes = 1
		player.jumps = player.MAX_JUMPS
	player.apply_gravity(delta)
	check_for_jump()
	check_for_drop_through()
	check_for_attack()
	check_for_special()
	check_for_crouch()
	check_for_super_run()
