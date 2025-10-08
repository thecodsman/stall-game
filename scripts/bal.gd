class_name Ball extends CharacterBody2D

const MAX_OWNER_LEVEL : int = 2
@export_category("movement")
@export  var BASE_GRAVITY          : float             = 75
@export  var AIR_FRICTION          : float             = 0
@export  var AIR_SPEED             : float             = 0 # no air friction so nothing happens
@export_subgroup("water")
@export  var WATER_GRAVITY         : float             = 20
@export  var WATER_FRICTION        : float             = 5
@export  var WATER_SPEED           : float             = 50
@export  var WATER_SPIN_MULTIPLIER : float             = 3
@export_category("spin")
@export  var ROLL_RATIO_THRESHOLD  : float	## ratio of (spin * 100) to velocity needed to initiate a wall roll
@export  var MIN_SPIN_FOR_ROLL     : float
@export_category("score")
@export  var SCORRABLE             : bool              = true
@export  var SCORE_LINE_HEIGHT     : float             = 20
@export  var WIN_EFFECT            : PackedScene
@onready var rotate_node           : Node2D            = $rotate_node
@onready var scale_node            : Node2D            = $rotate_node/scale_node
@onready var sprite                : Sprite2D          = $rotate_node/scale_node/Sprite2D
@onready var bounce_sfx            : AudioStreamPlayer = $bounce_sfx
@onready var collision_shape       : CollisionShape2D  = $CollisionShape2D
@onready var trail                 : TrailFX           = $trail_fx
var gravity                : float   = BASE_GRAVITY
var air_friction           : float   = AIR_FRICTION
var air_speed              : float   = AIR_SPEED
var owner_index            : int     = -1 ## player index of the owner of the ball
var owner_level            : int     = 0  ## level of ownership
var owner_color            : Color
var combo                  : int     = 0
var combo_owner            : int     = -1
var spin                   : float   = 0
var spin_mult              : float   = 1
var colliding_prev_frame   : bool    = false
var stalled                : bool    = false
var staller                : Player
var damage                 : float   = 1
var time_scale             : float   = 1
var prev_vel               : Vector2 = Vector2.ZERO
var prev_scale             : Vector2 = Vector2(1,1)
var velocity_entering_roll : Vector2
var spin_entering_roll     : float
var scorrable              : bool    = false
var stage_size             : Vector2
var highest_speed          : float
var highest_spin           : float
var server                 : Player
var outline_color		   : Color = Color.WHITE :
	set(color):
		outline_color = color
		if not sprite: return
		sprite.material.set_shader_parameter("outline_color", color)
var outline				   : bool = true :
	set(_outline):
		outline = _outline
		if not sprite: return
		if outline == true:
			sprite.material.set_shader_parameter("thickness", 1)
		else:
			sprite.material.set_shader_parameter("thickness", 0)


enum State {
	INACTIVE,
	NORMAL,
	WALL_ROLL,
	STALLED
	}
var state : State = State.INACTIVE


func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	UI.bal_meter.set_value(0)
	set_physics_process(multiplayer.get_unique_id() == 1)
	await get_tree().physics_frame
	trail.start()


func _physics_process(delta : float) -> void:
	var true_velocity : Vector2 = velocity
	if highest_speed < velocity.length(): highest_speed = velocity.length()
	if highest_spin < spin: highest_spin = velocity.length()
	delta    *= time_scale
	velocity *= time_scale
	_update_state(delta)
	if time_scale == 0:
		velocity = true_velocity
	else:
		velocity /= time_scale
	global_position.x = fposmod(global_position.x, stage_size.x)
	global_position.y = fposmod(global_position.y, stage_size.y)


func check_for_winner() -> void:
	if not SCORRABLE || not scorrable : return
	if owner_level < MAX_OWNER_LEVEL  : return
	if Globals.round_ending           : return
	give_point_to_winner.rpc(owner_index)
	var highest_score : int = 0
	for i : int in range(Globals.scores.size()):
		var score : int = Globals.scores[i]
		if score > highest_score: highest_score = score
	if highest_score >= Globals.points_to_win:
		Globals.end_match.rpc(owner_index)
	else:
		Globals.end_round.rpc(owner_index)


@rpc("authority", "call_local", "reliable")
func give_point_to_winner(winner : int) -> void:
	Globals.scores[winner - 1] += 1
	Globals.scores_changed.emit(Globals.scores)
	Globals.stats["max_speed"]  = highest_speed
	Globals.stats["max_spin"]   = highest_spin
	combo = 0
	combo_owner = -1
	var win_effect : Node2D = WIN_EFFECT.instantiate()
	win_effect.global_position = global_position
	win_effect.modulate = modulate
	$"/root/stage".add_child(win_effect)


func bounce(raw_vel : Vector2, collision : KinematicCollision2D) -> void:
	if (abs(spin * 100) / raw_vel.length()) > ROLL_RATIO_THRESHOLD && not colliding_prev_frame && abs(spin) > MIN_SPIN_FOR_ROLL:
		set_state(State.WALL_ROLL)
		velocity = raw_vel
		velocity_entering_roll = velocity
		spin_entering_roll = spin
	elif raw_vel.length() > 5:
		spin *= -0.75
		if velocity.length() > 90:
			Globals.camera.screen_shake(velocity.length() * 0.05, velocity.length() * 0.02, 5)
		bounce_sfx.volume_linear = raw_vel.length() * 0.05
		bounce_sfx.pitch_scale = randf_range(0.9,1.1)
		bounce_sfx.play()
		velocity = raw_vel.bounce(collision.get_normal().rotated(clampf(spin*0.1, -PI/4,PI/4)))
		velocity *= 0.60
		await get_tree().physics_frame
		freeze_frame(0.001 * velocity.length())


func juice_it_up() -> void:
	var width  : float = clampf(velocity.length() * 0.01, 1, 2)
	var height : float = 1/width
	var angle  : float = wrapf(velocity.angle(), -PI/2, PI/2)
	if get_slide_collision_count() > 0 && prev_vel.length() > 20 && state == State.NORMAL: 
		width = prev_scale.y
		height = prev_scale.x
		scale_node.scale = Vector2(width,height)
		rotate_node.rotation = angle
		prev_vel = velocity
		prev_scale = Vector2(width,height)
		return
	scale_node.scale = Vector2(width,height)
	if velocity.length() > 10: rotate_node.rotation = angle
	prev_vel = velocity
	prev_scale = Vector2(width,height)


@rpc("any_peer", "call_local", "reliable")
func update_color(color : Color, index : int) -> void:
	if index != owner_index: color = owner_color
	else: owner_color = color
	match owner_level:
		0:
			modulate = Color.WHITE
		1:
			modulate    = color
			modulate.s *= 0.5
			modulate.h += 0.015
		2:
			modulate = color
	trail.add_new_color(modulate)
	UI.bal_meter.set_progress_tint(color)
	UI.bal_meter.set_value(50*owner_level)


func spawn_smoke(pos : Vector2) -> void:
	var smoke_scene : PackedScene = preload("res://particles/smoke.tscn")
	var smoke : GPUParticles2D = smoke_scene.instantiate()
	add_child(smoke)
	smoke.position = pos
	smoke.emitting = true
	await smoke.finished
	smoke.queue_free()


func freeze_frame(time : float) -> void:
	if not get_tree(): return
	time_scale = 0
	await get_tree().create_timer(time).timeout
	time_scale = 1


func set_state(new_state : State) -> void:
	if state == new_state: return
	_exit_state()
	state = new_state
	_enter_state()


func _enter_state() -> void:
	match state:
		State.WALL_ROLL:
			floor_snap_length = 10
			motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _update_state(delta : float) -> void:
	match state:
		State.INACTIVE:
			if not server: return
			global_position.y = lerpf(
					global_position.y,
					server.global_position.y,
					5 * delta
			)
			const offset : float = 8
			var   side   : int   = sign((stage_size.x / 2) - global_position.x)
			global_position.x = lerpf(
					global_position.x,
					server.global_position.x + (offset * side),
					5 * delta
			)

		State.NORMAL:
			var raw_vel : Vector2 = velocity
			if not scorrable && global_position.y < stage_size.y - SCORE_LINE_HEIGHT:
				scorrable = true
				if owner_level >= MAX_OWNER_LEVEL: Globals.score_line.activate()
			sprite.rotation += (spin * delta) * 20
			spin = lerpf(spin, 0, 0.5*delta)
			velocity = velocity.rotated((spin * 0.5 * delta * spin_mult))
			if velocity.length() > air_speed:
				velocity = velocity.lerp(Vector2(air_speed,0).rotated(velocity.angle()), air_friction * delta)
			juice_it_up()
			if owner_index != -1: velocity.y += gravity * delta
			move_and_slide()
			for i : int in get_slide_collision_count():
				var collision : KinematicCollision2D = get_slide_collision(i)
				if not collision: return
				var collider : TileMapLayer = collision.get_collider()
				var pos : Vector2i = collider.get_coords_for_body_rid((collision.get_collider_rid()))
				var tile : TileData = collider.get_cell_tile_data(pos)
				bounce(raw_vel, collision)
				if is_on_floor_only() && tile.get_custom_data("floor") && is_multiplayer_authority(): check_for_winner()
			colliding_prev_frame = get_slide_collision_count() > 0

		State.WALL_ROLL:
			const WALL_RIDE_SPEED : float = 15
			var collision_info : KinematicCollision2D = get_last_slide_collision()
			if not collision_info && state == State.WALL_ROLL:
				set_state(State.NORMAL)
				return
			var normal      : Vector2      = collision_info.get_normal()
			var collider    : TileMapLayer = collision_info.get_collider()
			var pos         : Vector2i     = collider.get_coords_for_body_rid((collision_info.get_collider_rid()))
			var tile        : TileData     = collider.get_cell_tile_data(pos)
			var move_dir    : Vector2      = normal.rotated((PI/2)*sign(spin))
			var gravity_dir : Vector2      = normal.rotated(PI)
			if (
					normal == Vector2.UP &&
					tile.get_custom_data("floor") == true
			):
				check_for_winner()
			up_direction = normal
			apply_floor_snap()
			juice_it_up()
			sprite.rotation += (spin * delta) * 20
			if (
				abs(spin_entering_roll * 100) / velocity_entering_roll.length() >
				ROLL_RATIO_THRESHOLD * 1.5 &&
				abs(spin) > abs(spin_entering_roll) * 0.5
			):
				spin = lerpf(spin, 0, 0.5*delta)
				velocity = velocity.lerp(Vector2.ZERO, 7*delta)
				spawn_smoke(to_local(collision_info.get_position()))
				Globals.camera.screen_shake(3, 2, 3)
			else:
				velocity = velocity.lerp(move_dir * spin * WALL_RIDE_SPEED * damage, 5*delta)
				spin = lerpf(spin, 0, 1*delta)
				if not Engine.get_physics_frames() % 10: spawn_smoke(to_local(collision_info.get_position()))
			move_and_slide()
			velocity += gravity_dir
			if abs(spin) < abs(spin_entering_roll) * 0.25: set_state(State.NORMAL)

		State.STALLED:
			if velocity.length() > 2 || not staller: set_state(State.NORMAL)
			scorrable = false
			global_position = staller.ball_holder.global_position
			spin = lerpf(spin, 0, 2*delta)


func _exit_state() -> void:
	match state:
		State.INACTIVE:
			outline = false

		State.WALL_ROLL:
			var wall_exit_velocity : float = spin * 25 * damage
			var collision_info : KinematicCollision2D = get_last_slide_collision()
			floor_snap_length = 1
			motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
			up_direction = Vector2.UP
			if not collision_info: return
			var normal : Vector2 = collision_info.get_normal()
			velocity = wall_exit_velocity * normal

		State.STALLED:
			staller.ball = null
			staller.is_ball_stalled = false
			staller = null


func _on_water_detector_water_entered() -> void:
	velocity *= 0.45
	gravity = WATER_GRAVITY
	air_friction = WATER_FRICTION
	air_speed = WATER_SPEED
	spin_mult = WATER_SPIN_MULTIPLIER


func _on_water_detector_water_exited() -> void:
	gravity = BASE_GRAVITY
	air_friction = AIR_FRICTION
	air_speed = AIR_SPEED
	spin_mult = 1
