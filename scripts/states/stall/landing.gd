extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("landing")
	player.slide_boost_strength = 1
	player.jumps = player.MAX_JUMPS
	player.dashes = 1

func physics_update(delta : float) -> void:
	var landing_friction : float = 7
	player.slide_boost_strength = lerpf(player.slide_boost_strength, 0, 30*delta)
	if player.is_on_floor():
		player.velocity = player.velocity.lerp(Vector2.ZERO, landing_friction*delta)
	if player.anim.current_animation == "":
		finished.emit("Idle")
	check_for_attack()
	check_for_jump()

