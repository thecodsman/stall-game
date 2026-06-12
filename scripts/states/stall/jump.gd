extends PlayerState

@export var max_jump_angle : float = 45 :
	get(): return deg_to_rad(max_jump_angle)


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
	if not is_jump_pressed && player.jumps > 0 && player.anim.current_animation == "jump":
		player.velocity.y = hop_velocity
		if player.jump != player.Jump.NORMAL:
			player.velocity.x += hop_velocity * -player.sprite.scale.x * 0.5
		player.anim.play("rise")
		player.jumps -= 1
		player.jump_sfx.play()
		finished.emit("Air")
	elif player.anim.current_animation == "" && player.jumps > 0:
		var final_jump_vel : Vector2 = Vector2(0, jump_velocity)
		final_jump_vel = final_jump_vel.rotated(max_jump_angle * player.input.direction.x)
		player.velocity = final_jump_vel
		#player.velocity.y = jump_velocity
		player.anim.play("rise")
		player.jump_sfx.play()
		player.jumps -= 1
		finished.emit("Air")
	check_for_dash()


