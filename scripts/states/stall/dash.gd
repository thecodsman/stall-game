extends PlayerState

const dash_time : float = 0.1


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("dash")
	player.velocity = player.input.direction * player.DASH_SPEED
	await get_tree().create_timer(dash_time).timeout
	if state_machine.state != self: return
	finished.emit("Air")


func physics_update(_delta : float) -> void:
	check_for_attack()
	if player.is_on_floor(): finished.emit("Landing")
	if Engine.get_physics_frames() % 3: return
	player.spawn_afterimage.rpc()
