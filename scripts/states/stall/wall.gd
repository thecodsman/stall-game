extends PlayerState

var on_wall_prev_frame : bool = false


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("on_wall")
	player.jumps = player.MAX_JUMPS - 1
	player.dashes = 1
	player.gravity = player.BASE_GRAVITY*0.1
	if player.get_slide_collision_count() < 1: 
		player.sprite.scale.x = player.get_last_slide_collision().get_normal().x * -1


func physics_update(delta : float) -> void:
	on_wall_prev_frame = true
	check_for_wall_jump()
	player.velocity.y = lerpf(player.velocity.y, 0 , 5*delta)
	player.apply_gravity(delta)
	player.direction = player.input.direction.x
	var wall_dir : float = 0
	if player.get_slide_collision_count() > 0:
		wall_dir = -player.get_last_slide_collision().get_normal().x
	player.wall_jump_dir = wall_dir
	if player.is_on_wall_only() && sign(player.direction) != wall_dir && on_wall_prev_frame:
		on_wall_prev_frame = false
		await get_tree().create_timer(0.075).timeout
		if state_machine.state != self: return
		finished.emit("Air")
	elif !player.is_on_wall_only() && on_wall_prev_frame:
		player.on_wall_prev_frame = false
		await get_tree().create_timer(0.075).timeout
		if state_machine.state != self: return
		finished.emit("Air")


func exit() -> void:
	player.gravity = player.BASE_GRAVITY
