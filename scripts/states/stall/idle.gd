extends PlayerState

var direction : float

func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("idle")
	player.slide_boost_strength = 0
	player.jump = player.Jump.NORMAL
	if not player.is_on_floor(): finished.emit("Air")


func physics_update(delta : float) -> void:
	direction = player.input.direction.x
	player.velocity.x = lerpf(player.velocity.x, 0, player.FRICTION*delta)
	player.apply_gravity(delta)
	var side_input : bool = (
			abs(angle_difference(player.input.direction.angle(), 0)) < PI/4 ||
			abs(angle_difference(player.input.direction.angle(), PI)) < PI/4
		)
	if player.input.just_smashed() && side_input:
		finished.emit("InitialSprint")
	elif direction && side_input:
		finished.emit("Walk")
	if not player.is_on_floor():
		await get_tree().create_timer(player.COYOTE_TIME).timeout
		player.jumps -= 1
		finished.emit("Air")
	else:
		player.dashes = 1
		player.jumps = player.MAX_JUMPS
		player.fast_falling = false
	check_for_attack()
	check_for_jump()
	check_for_crouch()
