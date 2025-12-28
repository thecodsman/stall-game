extends PlayerState

const run_speed_mult : float = 0.6
var run_dash_timer : Timer = Timer.new()

func _ready() -> void:
	add_child(run_dash_timer)

func enter(_previous_state : String, _data : Dictionary = {}) -> void:
	player.anim.play("run_dash")
	player.spawn_smoke(Vector2(0,4))
	player.velocity.x += sign(player.direction) * player.RUN_SPEED * 0.6
	if sign(player.velocity.x) == 0: return
	player.sprite.scale.x = sign(player.velocity.x)


func physics_update(delta : float) -> void:
	player.direction = player.input.direction.x
	var _accel : float = player.ACCEL * 0.66
	if player.in_water: player.velocity = player.velocity.lerp(Vector2.ZERO, player.WATER_GROUND_FRICTION * delta)
	if player.direction: player.move(delta, _accel, player.RUN_SPEED, false)
	else: player.velocity.x = lerpf(player.velocity.x, 0, 1*delta)
	if player.anim.current_animation != "run_dash" && sign(player.input.direction.x) == player.sprite.scale.x:
		finished.emit("Run")
		return
	elif player.anim.current_animation != "run_dash" && (sign(player.input.direction.x) == -player.sprite.scale.x || player.input.direction.x == 0):
		finished.emit("Idle")
		return
	if not player.is_on_floor(): finished.emit("Air")
	if abs(angle_difference(player.input.direction.angle(), PI/2)) < PI/4:
		if check_for_jump(false): player.jump = player.Jump.HYPER
	else:
		check_for_jump()
	check_for_super_run()
	if check_for_attack(): player.attack = player.Attack.DASH
	if not player.input.just_smashed(): return
	player.sprite.scale.x = sign(player.direction)
	player.anim.play("RESET")
	player.anim.play("run_dash")
	player.spawn_smoke(Vector2(0,4))
	player.velocity.x = sign(player.direction) * player.RUN_SPEED

