extends PlayerState


func _ready() -> void:
	await owner.ready
	player.anim.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(animation : String) -> void:
	if animation != "stall_kick": return
	finished.emit("Idle")
	

func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.set_collision_mask_value(3, false)
	player.anim.play("stall_kick")


func physics_update(delta : float) -> void:
	player.apply_gravity(delta)
	player.velocity.lerp(Vector2.ZERO, 10*delta)


func exit() -> void:
	player.set_collision_mask_value(3, true)
	player.is_ball_stalled = false
