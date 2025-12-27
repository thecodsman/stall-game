extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("skid")


func physics_update(delta : float) -> void:
	check_for_jump()
	check_for_attack()
	if not Engine.get_physics_frames() % 15: player.spawn_smoke(Vector2(2*player.sprite.scale.x,4))
	player.velocity.x = lerpf(player.velocity.x, 0, 2*delta)
	if player.anim.current_animation == "":
		player.sprite.scale.x *= -1
		finished.emit("SuperRun")
