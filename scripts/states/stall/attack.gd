extends PlayerState

var prev_state : String

func enter(previous_state : String, _data : Dictionary = {}) -> void:
	var input_dir : float = (player.input.direction * Vector2(player.sprite.scale.x, 1)).angle()
	prev_state = previous_state
	if prev_state == "Run" || prev_state == "InitialSprint" || prev_state == "SuperRun":
		player.attack = player.Attack.DASH
		player.kick_box.direction = Vector2(0.6,-0.4)
		player.kick_box.power = 45
	elif player.is_on_floor():
		if player.input.direction.length() <= player.input.NeutralZone:
			player.attack = player.Attack.NEUTRAL
			player.kick_box.direction = Vector2.from_angle(-0.261)
			player.kick_box.power = 35
		elif input_dir > PI * 0.25 && input_dir < PI * 0.75: # slide kick
			player.attack = player.Attack.DOWN
			player.kick_box.direction = Vector2.UP
			player.kick_box.power = 45
		elif input_dir < -PI * 0.25 && input_dir > -PI * 0.75:
			player.attack = player.Attack.UP
			player.kick_box.direction = Vector2.UP
			player.kick_box.power = 25
		else:
			player.attack = player.Attack.SIDE
			player.kick_box.direction = Vector2(0.8,-0.2)
			player.kick_box.power = 55
	else:
		if player.input.direction.length() <= player.input.NeutralZone:
			player.attack = player.Attack.NAIR
			player.kick_box.direction = Vector2.ZERO
			player.kick_box.power = 48
		elif input_dir > PI * 0.25 && input_dir < PI * 0.75:
			player.attack = player.Attack.DAIR
			player.kick_box.direction = Vector2.DOWN
			player.kick_box.power = 70
		elif input_dir < PI * -0.25 && input_dir > PI * -0.75:
			player.attack = player.Attack.UPAIR
			player.kick_box.direction = Vector2.UP
			player.kick_box.power = 50
		elif input_dir >= PI * -0.25 && input_dir <= PI * 0.25:
			player.attack = player.Attack.FAIR
			player.kick_box.power = 60
			player.kick_box.direction = Vector2(0.9,-0.1)
		elif input_dir >= PI * 0.75 || input_dir <= PI * -0.75:
			player.attack = player.Attack.BAIR
			player.kick_box.power = 85
			player.kick_box.direction = Vector2(-0.8,0.2)
	# -----
	match player.attack:
		player.Attack.NEUTRAL:
			player.anim.play("neutral_attack")
		player.Attack.UP:
			player.anim.play("up_attack")
		player.Attack.SIDE:
			player.anim.play("side_attack")
		player.Attack.DOWN:
			player.anim.play("down_attack")
			player.kick_box.direction = Vector2.UP
			player.kick_collider.set_deferred("disabled", false)
			if player.slide_boost_strength > 0:
				player.velocity.x += player.MAX_SLIDE_BOOST_SPEED * player.slide_boost_strength * player.sprite.scale.x
				player.slide_boost_strength = 0
			else:
				player.velocity.x += player.SLIDE_SPEED * player.sprite.scale.x
		player.Attack.DASH:
			const DASH_ATTACK_SPEED_BOOST : float = 120
			player.anim.play("dash_attack")
			player.velocity.x = DASH_ATTACK_SPEED_BOOST * player.sprite.scale.x
		player.Attack.UPAIR:
			player.anim.play("upair")
		player.Attack.NAIR:
			player.anim.play("nair")
		player.Attack.DAIR:
			player.anim.play("dair")
		player.Attack.BAIR:
			player.anim.play("bair")
		player.Attack.FAIR:
			player.anim.play("fair")


func physics_update(delta : float) -> void:
	match player.attack:
		player.Attack.UP:
			check_for_jump()
			player.velocity.x = lerpf(player.velocity.x, 0, 7*delta)
			if not player.is_on_floor(): finished.emit("Air")
		player.Attack.NEUTRAL:
			check_for_jump()
			player.velocity.x = lerpf(player.velocity.x, 0, 7*delta)
			if not player.is_on_floor(): finished.emit("Air")
		player.Attack.DOWN:
			check_for_jump()
			player.velocity.x = lerpf(player.velocity.x, 0, 2*delta)
			if player.in_water: player.velocity.x = lerpf(player.velocity.x, 0, 5*delta)
			if abs(player.velocity.x) < 20: finished.emit("Idle")
			if not player.is_on_floor(): finished.emit("Air")
		player.Attack.SIDE:
			check_for_jump()
			player.velocity.x = lerpf(player.velocity.x, 0, 7*delta)
			if not player.is_on_floor(): finished.emit("Air")
		player.Attack.DASH:
			player.velocity.x = lerpf(player.velocity.x, 0, delta)
			if player.in_water: player.velocity.x = lerpf(player.velocity.x, 0, 5*delta)
			if player.anim.current_animation == "": finished.emit("Idle")
			if not player.is_on_floor(): finished.emit("Air")
		player.Attack.UPAIR:
			player.move(delta, player.air_accel, player.RUN_SPEED, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
			player.apply_gravity(delta)
			if player.is_on_floor(): finished.emit("Landing")
		player.Attack.NAIR:
			player.move(delta, player.air_accel, player.RUN_SPEED, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
			player.apply_gravity(delta)
			if player.is_on_floor(): finished.emit("Landing")
		player.Attack.DAIR:
			player.move(delta, player.air_accel, player.RUN_SPEED, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
			player.apply_gravity(delta)
			if player.is_on_floor(): finished.emit("Landing")
		player.Attack.BAIR:
			player.move(delta, player.air_accel, player.RUN_SPEED, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
			player.apply_gravity(delta)
			if player.is_on_floor(): finished.emit("Landing")
		player.Attack.FAIR:
			player.move(delta, player.air_accel, player.RUN_SPEED, false)
			player.velocity = player.velocity.lerp(Vector2.ZERO, player.air_friction*delta)
			player.apply_gravity(delta)
			if player.is_on_floor(): finished.emit("Landing")
	if player.anim.current_animation == "":
		finished.emit("Idle")
	check_for_fastfall()
	if player.kick_collider.disabled:
		check_for_dash()
		check_for_jump()


func exit() -> void:
	player.sprite.scale.y = 1
	player.anim.play("RESET")
	player.kick_collider.set_deferred("disabled", true)
