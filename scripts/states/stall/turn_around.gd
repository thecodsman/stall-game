extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("turn_around")
	player.spawn_smoke(Vector2(0,4))


func physics_update(delta : float) -> void:
	check_for_jump()
	check_for_attack()
	player.velocity.x = lerpf(player.velocity.x, 0, player.FRICTION*delta)
	if player.anim.current_animation == "":
		player.sprite.scale.x *= -1
		finished.emit("Run")

	player.spawn_smoke(Vector2(0,4))

