extends PlayerState

var stun_timer : int
var rotation_direction : int = 1


func enter(_previous_state : String, data : Dictionary = {}) -> void:
	stun_timer = data["hit_stun_time"]
	player.anim.play("hitstun")
	player.sprite.frame = randi_range(0, player.sprite.hframes - 1)
	rotation_direction = (randi_range(0, 1) * 2) - 1


func physics_update(delta : float) -> void:
	player.apply_gravity(delta)
	if player.is_on_floor():
		player.velocity.x = lerpf(player.velocity.x, 0, player.FRICTION * delta)
		player.sprite.rotation = 0
	else:
		player.velocity.x = lerpf(player.velocity.x, 0, player.AIR_FRICTION * delta)
		player.sprite.rotation += PI * rotation_direction * delta
	if stun_timer > 1:
		stun_timer -= 1
	else:
		finished.emit("Idle")


func exit() -> void:
	player.sprite.rotation = 0
