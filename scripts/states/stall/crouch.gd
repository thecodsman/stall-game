extends PlayerState

var crouch_friction : float = 6

func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("crouch")


func physics_update(delta : float) -> void:
	player.velocity.x = lerpf(player.velocity.x, 0, crouch_friction * delta)
	if not check_for_crouch(): finished.emit("Idle")
	if not player.is_on_floor(): finished.emit("Air")
	check_for_attack()
	if check_for_jump(false): player.jump = player.Jump.SUPER
	check_for_special()
	check_for_drop_through()
