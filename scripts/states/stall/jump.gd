extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("jump")


func physics_update(delta : float) -> void:
	var is_jump_pressed : bool = player.input.is_joy_button_pressed(JOY_BUTTON_A)
	player.velocity.x = lerpf(player.velocity.x, 0, player.AIR_FRICTION*delta)
	var hop_velocity : float
	var jump_velocity : float
	match player.jump:
		player.Jump.NORMAL:
			hop_velocity = player.SHORT_HOP_VELOCITY
			jump_velocity = player.FULL_JUMP_VELOCITY
		player.Jump.SUPER:
			hop_velocity = player.SUPER_HOP_VELOCITY
			jump_velocity = player.SUPER_JUMP_VELOCITY
		player.Jump.HYPER:
			hop_velocity = player.HYPER_HOP_VELOCITY
			jump_velocity = player.HYPER_JUMP_VELOCITY
		player.Jump.ULTRA:
			hop_velocity = player.ULTRA_HOP_VELOCITY
			jump_velocity = player.ULTRA_JUMP_VELOCITY
	var dir : Vector2 = player.input.direction * Vector2(player.sprite.scale.x, 1)
	if not is_jump_pressed && player.jumps > 0 && player.anim.current_animation == "jump":
		if dir.length() > 0.9 && abs(angle_difference(dir.angle(), PI)) < PI/8:
			player.anim.play("backflip")
			player.velocity.y = player.SHORT_FLIP_VELOCITY
			player.jumps -= 1
			finished.emit("Air")
			return
		player.velocity.y = hop_velocity
		if player.jump != player.Jump.NORMAL: player.velocity.x += hop_velocity * -player.sprite.scale.x * 0.5
		player.anim.play("rise")
		player.jumps -= 1
		player.jump_sfx.play()
		finished.emit("Air")
	elif player.anim.current_animation == "" && player.jumps > 0:
		if dir.length() > 0.9 && abs(angle_difference(dir.angle(), PI)) < PI/8:
			player.anim.play("backflip")
			player.velocity.y = player.BACKFLIP_VELOCITY
			player.jumps -= 1
			finished.emit("Air")
			return
		player.velocity.y = jump_velocity
		player.anim.play("rise")
		player.jump_sfx.play()
		player.jumps -= 1
		finished.emit("Air")


