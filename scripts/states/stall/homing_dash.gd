extends PlayerState

const dash_time : float = 0.4
const initial_dash_mult : float = 0.65
const homing_speed : float = 10
const steering_strength : float = 8
const dash_speed_mult : float = 1.5


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("dash")
	var dir2ball : float = (Globals.ball.global_position - player.global_position).angle()
	player.velocity = player.DASH_SPEED * initial_dash_mult * Vector2.from_angle(dir2ball)
	await get_tree().create_timer(dash_time).timeout
	if state_machine.state != self: return
	finished.emit("Air")


func physics_update(delta : float) -> void:
	check_for_attack()
	if not Globals.ball: return
	var distance2ball : Vector2 = Globals.ball.global_position - player.global_position
	var dir2ball : float = (distance2ball).angle()
	player.velocity = player.velocity.lerp(player.DASH_SPEED * dash_speed_mult * Vector2.from_angle(dir2ball), homing_speed*delta)
	player.velocity = player.velocity.lerp(player.DASH_SPEED * player.input.direction, steering_strength*delta)
	if distance2ball.length() < 12: finished.emit("Air")
	if player.is_on_floor(): finished.emit("Landing")
	if Engine.get_physics_frames() % 3: return
	player.spawn_afterimage.rpc()
