class_name PlayerState extends StateComponent

var player : Player


func check_for_special() -> bool:
	var is_special_pressed : bool = player.input.is_joy_button_pressed(JOY_BUTTON_B)
	if is_special_pressed || player.ball:
		finished.emit("Stall")
		return true
	return false


func check_for_jump(is_normal : bool = true) -> bool:
	if player.input.is_button_just_pressed(JOY_BUTTON_A):
		if player.jumps <= 0: return false
		if is_normal: player.jump = player.Jump.NORMAL
		finished.emit("Jump")
		return true
	return false


func check_for_crouch() -> bool:
	var dir_is_down : bool = (abs(angle_difference(player.input.direction.angle(), PI/2)) < PI/4)
	if dir_is_down && not player.input.neutral:
		finished.emit("Crouch")
		return true
	return false


func check_for_super_slide() -> bool:
	if abs(angle_difference(player.input.direction.angle(), PI/2)) < PI/4:
		finished.emit("SuperSlide")
		return true
	return false


func check_for_wall_jump() -> bool:
	if player.input.is_button_just_pressed(JOY_BUTTON_A):
		player.velocity.y = player.FULL_JUMP_VELOCITY
		player.velocity.x = (player.FULL_JUMP_VELOCITY * player.wall_jump_dir) * 0.65
		finished.emit("Air")
		player.gravity = player.BASE_GRAVITY
		return true
	return false
	

func check_for_attack() -> bool:
	if player.input.is_button_just_pressed(JOY_BUTTON_X):
		finished.emit("Attack")
		return true
	return false


func check_for_dash() -> bool:
	if player.input.is_button_just_pressed(JOY_BUTTON_RIGHT_SHOULDER, -1, true) && player.dashes > 0 && player.input.neutral == false:
		player.dashes -= 1
		finished.emit("Dash")
		return true
	elif player.input.is_button_just_pressed(JOY_BUTTON_RIGHT_SHOULDER, -1, true) && player.dashes > 0 && player.input.neutral == true && Globals.ball:
		player.dashes -= 1
		finished.emit("HomingDash")
		return true
	return false


func check_for_super_run() -> bool:
	if not player.input.is_button_just_pressed(JOY_BUTTON_RIGHT_SHOULDER): return false
	finished.emit("SuperRun")
	return true


func check_for_fastfall() -> bool:
	if player.input.just_smashed() && abs(angle_difference(player.input.direction.angle(), PI/2)) < PI/4 && player.velocity.y > -10 && not player.fast_falling:
		player.velocity.y = player.FAST_FALL_SPEED
		player.fast_falling = true
		player.spawn_spark(Vector2(4,-4))
		return true
	return false


func check_for_drop_through() -> bool:
	const platform_collision_layer : int = 4
	var threshold : float = 0.85
	if player.input.direction.y > threshold && not player.is_on_floor():
		player.set_collision_mask_value(platform_collision_layer, false)
		return true
	elif player.input.just_smashed() && (player.input.direction.angle() > PI*0.25 && player.input.direction.angle() < PI*0.75) && player.is_on_floor():
		player.set_collision_mask_value(platform_collision_layer, false)
		player.velocity.y = 10
		return true
	else:
		player.set_collision_mask_value(platform_collision_layer, true)
		return false
