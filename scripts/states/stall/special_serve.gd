extends PlayerState

@export var hackey_scene : PackedScene
@export var serve_power : float
@export var hackey_catch_collider : CollisionShape2D 
@export_group("serves")
@export var side_serve_vel : Vector2
@export var up_serve_vel : Vector2
@export var down_serve_vel : Vector2


func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("stall_kick")
	var input_dir : float = (player.input.direction * Vector2(player.sprite.scale.x, 1)).angle()
	var serve_vel : Vector2
	if player.input.direction.length() <= player.input.NeutralZone:
		hackey_catch_collider.set_deferred("disabled", false)
		await player.anim.animation_finished
		finished.emit("Idle")
		return
	elif abs(angle_difference(input_dir, 0)) < PI/4:
		serve_vel = side_serve_vel * Vector2(player.sprite.scale.x, 1)
	elif absf(angle_difference(input_dir, PI/2)) < PI/4:
		serve_vel = down_serve_vel
	elif absf(angle_difference(input_dir, -PI/2)) < PI/4:
		serve_vel = up_serve_vel
	var hackey_sack : CharacterBody2D = hackey_scene.instantiate()
	hackey_sack.velocity = serve_vel
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

func exit() -> void:
	hackey_catch_collider.set_deferred("disabled", true)
