extends PlayerState


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("jump")


