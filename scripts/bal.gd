class_name Ball extends CharacterBody2D

const MAX_OWNER_LEVEL : int = 2
var gravity : float = 75
var owner_index : int = -1 ## player index of the owner of the ball
var owner_level : int = 0 ## level of ownership
var owner_color : Color 
var spin : float = 0
var colliding_prev_frame : bool = false
var stalled : bool = false
var staller : Player
var damage : float = 1
var time_scale: float = 1
var prev_vel : Vector2 = Vector2.ZERO
var prev_scale : Vector2 = Vector2(1,1)
var velocity_entering_roll : Vector2
var spin_entering_roll : float
@onready var rotate_node : Node2D = $rotate_node
@onready var scale_node : Node2D = $rotate_node/scale_node
@onready var sprite : Sprite2D = $rotate_node/scale_node/Sprite2D
@onready var bounce_sfx : AudioStreamPlayer = $bounce_sfx
@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var trail : TrailFX = $trail_fx
@export var roll_ratio_threshold : float = 2 ## ratio of (spin * 100) to velocity needed to initiate a wall roll
@export var scorrable : bool = true

enum State {
	NORMAL,
	WALL_ROLL
	}
var state : State


func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	set_physics_process(multiplayer.get_unique_id() == 1)
	await get_tree().physics_frame
	trail.start()


func _physics_process(delta : float) -> void:
	var true_velocity : Vector2 = velocity
	delta *= time_scale
	velocity *= time_scale
	_update_state(delta)
	if time_scale == 0:
		velocity = true_velocity
	else:
		velocity /= time_scale


func check_for_winner() -> void:
	if not scorrable: return
	if owner_level < MAX_OWNER_LEVEL: return
	if UI.game_text.visible: return
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


func bounce(raw_vel : Vector2, collision : KinematicCollision2D) -> void:
	if (abs(spin * 100) / raw_vel.length()) > roll_ratio_threshold && not colliding_prev_frame:
		set_state(State.WALL_ROLL)
		velocity = raw_vel
		velocity_entering_roll = velocity
		spin_entering_roll = spin
	elif not colliding_prev_frame:
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
	else:
		velocity = raw_vel.bounce(collision.get_normal().rotated(clampf(spin*0.1, -PI/4,PI/4)))


func juice_it_up() -> void:
	var width : float = clampf(velocity.length() * 0.01, 1, 2)
	var height : float = 1/width
	var angle : float = wrapf(velocity.angle(), -PI/2, PI/2)
	if get_slide_collision_count() > 0 && prev_vel.length() > 20 && state == State.NORMAL: 
		width = prev_scale.y
		height = prev_scale.x
		scale_node.scale = Vector2(width,height)
		rotate_node.rotation = angle
		prev_vel = velocity
		prev_scale = Vector2(width,height)
		return
	scale_node.scale = Vector2(width,height)
	rotate_node.rotation = angle
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
			modulate = color * 1.75
		2:
			modulate = color
	trail.add_new_color(modulate)


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
		State.NORMAL:
			var raw_vel : Vector2 = velocity
			if owner_level > MAX_OWNER_LEVEL: owner_level = MAX_OWNER_LEVEL
			sprite.rotation += (spin * delta) * 20
			spin = lerpf(spin, 0, 0.5*delta)
			velocity = velocity.rotated((spin * 0.5 * delta))
			juice_it_up()
			if stalled:
				if velocity.length() > 2:
					stalled = false
					staller.ball = null
					staller.is_ball_stalled = false
				global_position = staller.ball_holder.global_position
				return
			if owner_index != -1: velocity.y += gravity * delta
			move_and_slide()
			for i : int in get_slide_collision_count():
				var collision : KinematicCollision2D = get_slide_collision(i)
				if not collision: return
				var collider : TileMapLayer = collision.get_collider()
				var tile : TileData = collider.get_cell_tile_data(collider.get_coords_for_body_rid((collision.get_collider_rid())))
				bounce(raw_vel,collision)
				if is_on_floor_only() && tile.get_custom_data("floor") && is_multiplayer_authority(): check_for_winner()
			colliding_prev_frame = get_slide_collision_count() > 0
		
		State.WALL_ROLL:
			const WALL_RIDE_SPEED : float = 15
			var collision_info : KinematicCollision2D = get_last_slide_collision()
			if not collision_info:
				set_state(State.NORMAL)
				return
			var normal : Vector2 = collision_info.get_normal()
			var move_dir : Vector2 = normal.rotated((PI/2)*sign(spin))
			var gravity_dir : Vector2 = normal.rotated(PI)
			up_direction = normal
			apply_floor_snap()
			juice_it_up()
			sprite.rotation += (spin * delta) * 20
			if (abs(spin_entering_roll * 100) / velocity_entering_roll.length()) > roll_ratio_threshold * 1.5 && abs(spin) > abs(spin_entering_roll) * 0.5:
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


func _exit_state() -> void:
	match state:
		State.WALL_ROLL:
			var wall_exit_velocity : float = spin * 25 * damage
			var collision_info : KinematicCollision2D = get_last_slide_collision()
			floor_snap_length = 1
			motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
			up_direction = Vector2.UP
			if not collision_info: return
			var normal : Vector2 = collision_info.get_normal()
			velocity = wall_exit_velocity * normal
