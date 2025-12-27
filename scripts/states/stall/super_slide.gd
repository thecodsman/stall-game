extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("player.super_slide")


func physics_update(delta : float) -> void:
	if player.in_water: player.velocity = player.velocity.lerp(Vector2.ZERO, player.WATER_GROUND_FRICTION * delta)
	if abs(player.velocity.x) < 30: finished.emit("Idle")
	player.velocity.x = lerpf(player.velocity.x, 0, 1*delta)
	player.apply_gravity(delta)
	if check_for_jump(false): player.jump = player.Jump.ULTRA
	check_for_attack()
	check_for_special()

