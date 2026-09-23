extends PlayerState

@export var hackey_scene : PackedScene
@export var serve_power : float


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("stall_kick")
	var hackey_sack : CharacterBody2D = hackey_scene.instantiate()
	hackey_sack.velocity = Vector2(0, -serve_power)
	hackey_sack.global_position = player.global_position
	hackey_sack.modulate = Globals.current_player_colors[player.player_index - 1]
	if player.hackeys_out < player.MAX_HACKEYS:
		$"/root/stage/SubViewportContainer/game".add_child(hackey_sack)
		player.hackeys_out += 1
	hackey_sack.player = player
	await player.anim.animation_finished
	finished.emit("Idle")


func physics_update(delta : float) -> void:
	if player.is_on_floor(): player.velocity.x = lerpf(player.velocity.x, 0, player.FRICTION*delta)
	player.apply_gravity(delta)
