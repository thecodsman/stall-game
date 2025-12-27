extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
		player.anim.play("walk")


func physics_update(delta : float) -> void:
	if not player.move(delta, player.ACCEL, player.WALK_SPEED): finished.emit("Idle")
	if player.in_water: player.velocity = player.velocity.lerp(Vector2.ZERO, player.WATER_GROUND_FRICTION * delta)
	if not player.is_on_floor():
		await get_tree().create_timer(player.COYOTE_TIME).timeout
		finished.emit("Air")
	else:
		player.dashes = 1
		player.jumps = player.MAX_JUMPS
	if player.input.just_smashed():
		finished.emit("InitialSprint")
	player.apply_gravity(delta)
	check_for_jump()
	check_for_drop_through()
	check_for_attack()
	check_for_special()
	check_for_crouch()
	check_for_super_run()

func exit() -> void:
	player.anim.play("walk")
