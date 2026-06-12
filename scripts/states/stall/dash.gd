extends PlayerState

@export var dash_time : float = 0.1
@export var end_air_drag : float = 0.5
@export var dash_end_time : float = 0.3
var dash_ending : bool = false


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("dash")
	player.velocity = player.input.direction * player.DASH_SPEED
	await get_tree().create_timer(dash_time).timeout
	dash_ending = true
	await get_tree().create_timer(dash_end_time).timeout
	if state_machine.state != self: return
	finished.emit("Air")


func physics_update(delta : float) -> void:
	check_for_attack()
	if dash_ending: player.velocity = player.velocity.lerp(Vector2.ZERO, end_air_drag * delta)
	if player.is_on_floor(): finished.emit("Landing")
	if player.is_on_wall(): finished.emit("Wall")
	if Engine.get_physics_frames() % 3: return
	player.spawn_afterimage.rpc()
