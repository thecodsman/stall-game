extends PlayerState

@export var block_node : Node2D


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("block")
	block_node.show()


func physics_update(delta : float) -> void:
	player.velocity.x = lerpf(player.velocity.x, 0, player.FRICTION*delta)
	player.apply_gravity(delta)
	if player.input.direction.length() > 0.5:
		block_node.rotation = player.input.direction.angle()
	if not player.input.is_joy_button_pressed(JOY_BUTTON_LEFT_SHOULDER):
		finished.emit("Idle")


func exit() -> void:
	block_node.hide()
	block_node.rotation = 0
