class_name Player extends CharacterBody2D

@export var dead_zone : float = 0.09
const SPEED : float = 100.0
const ACCEL : float = 20.0
const JUMP_VELOCITY : float = -230.0
const BASE_GRAVITY : float = 700.0
const FRICTION : float = 20
const COYOTE_TIME : float = 0.05
var player_index : int = 0
var controller_index : int = 0
var id : int = 1 :
	set(new_id):
		id = new_id
		$Input.set_multiplayer_authority(id)
var gravity : float = BASE_GRAVITY
var direction : float = 0
var dir_prev_frame : float = 0
var can_jump : bool = false
var j_prev_frame : bool = false
var wall_jump_dir : float = 0
var dash_speed : float = 200.0
var dashes : int = 1
var on_wall_prev_frame : bool = false
var run_dash_timer : Timer = Timer.new()
var is_ball_stalled : bool = false
@onready var input : PlayerInput = $Input
@onready var ball_holder = $Sprite2D/ball_holder
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var bonk_box_collider = $Sprite2D/bonk_box/CollisionShape2D
@onready var jump_sfx = $jump_sfx
@onready var stall_box = $Sprite2D/stall_box

enum State {
	IDLE,
	WALK,
	RUN,
	RUN_DASH,
	JUMP,
	AIR,
	KICK,
	WALL,
	DASH,
	STALL,
	STALL_KICK
	}
var state : State


func _ready():
	sprite.self_modulate = self_modulate
	print("instance:%s, authority:%s" % [multiplayer.get_unique_id(), id])
	add_child(run_dash_timer)
	anim.animation_finished.connect(_on_animation_finished)
	#set_physics_process(id == multiplayer.get_unique_id())


func _physics_process(delta: float) -> void:
	update_state(delta)
	move_and_slide()


@rpc("any_peer", "call_local", "unreliable_ordered")
func set_state(new_state : State):
	if state == new_state: return
	exit_state()
	state = new_state
	enter_state()


var charged_kick : bool = false
func enter_state():
	match state:
		State.IDLE:
			anim.play("idle")
		State.WALK:
			anim.play("walk")
		State.RUN:
			anim.play("run")
		State.RUN_DASH:
			anim.play("run_dash")
			velocity.x = sign(direction) * SPEED
		State.DASH:
			anim.play("dash")
			velocity = input.direction * dash_speed
			await get_tree().create_timer(0.1).timeout
			set_state.rpc(State.AIR)
		State.JUMP:
			anim.play("jump")
		State.AIR:
			can_jump = false
		State.KICK:
			anim.play("kick_charge")
			bonk_box_collider.disabled = true
		State.WALL:
			anim.play("on_wall")
			can_jump = true
			dashes = 1
			gravity = BASE_GRAVITY*0.1
		State.STALL:
			anim.play("stall")
			set_collision_mask_value(3, false)
			bonk_box_collider.disabled = true
		State.STALL_KICK:
			anim.play("stall_kick")
			set_collision_mask_value(3, false)
			bonk_box_collider.disabled = true


var turned_around : bool = false
func update_state(delta : float):
	match state:
		State.IDLE:
			direction = input.direction.x
			velocity.x = lerpf(velocity.x, 0, 10*delta)
			check_for_jump()
			check_for_drop_through()
			check_for_kick()
			check_for_special()
			apply_gravity(delta)
			if abs(direction) < dead_zone: direction = 0
			if direction:
				await get_tree().create_timer(0.03).timeout
				if abs(direction) > 0.5: set_state.rpc(State.RUN_DASH)
				else: set_state.rpc(State.WALK)
			if not is_on_floor():
				await get_tree().create_timer(COYOTE_TIME).timeout
				set_state.rpc(State.AIR)
			else:
				dashes = 1
				can_jump = true

		State.WALK:
			if not move(delta, ACCEL, SPEED * 0.65): set_state.rpc(State.IDLE)
			check_for_jump()
			check_for_drop_through()
			check_for_kick()
			check_for_special()
			if not is_on_floor():
				await get_tree().create_timer(COYOTE_TIME).timeout
				set_state.rpc(State.AIR)
			else:
				dashes = 1
				can_jump = true
			apply_gravity(delta)

		State.RUN:
			direction = input.direction.x
			if abs(direction) < dead_zone: direction = 0
			if not direction && abs(velocity.x) < 1: set_state.rpc(State.IDLE)
			elif abs(velocity.x) > 10 && sign(direction) == sign(velocity.x) * -1 && not turned_around: 
				turned_around = true
				anim.play("turn_around")
			elif anim.current_animation == "":
				anim.play("run")
				move(delta)
			elif anim.current_animation == "run":
				move(delta)
				turned_around = false
			elif anim.current_animation == "turn_around":
				velocity.x = lerpf(velocity.x, 0, 10*delta)
			check_for_jump()
			check_for_drop_through()
			check_for_kick()
			check_for_special()
			if not is_on_floor():
				await get_tree().create_timer(0.1).timeout
				set_state.rpc(State.AIR)
			else:
				dashes = 1
				can_jump = true
			apply_gravity(delta)

		State.RUN_DASH:
			direction = input.direction.x
			if abs(direction) < dead_zone: direction = 0
			if direction:
				velocity.x = lerpf(velocity.x, direction * SPEED, ACCEL*0.5*delta)
			if anim.current_animation != "run_dash":
				set_state.rpc(State.RUN)
				return
			check_for_jump()
			check_for_kick()
			check_for_special()
			if not (direction * -sprite.scale.x > 0.9 && abs(dir_prev_frame) < 0.6): return
			sprite.scale.x = sign(direction)
			anim.play("run_dash")
			velocity.x = sign(direction) * SPEED

		State.JUMP:
			var is_jump_pressed = input.is_joy_button_pressed(JOY_BUTTON_A)
			if is_jump_pressed:
				if not j_prev_frame && can_jump:
					j_prev_frame = true
			elif not is_jump_pressed && j_prev_frame && can_jump:
				j_prev_frame = false
				if anim.current_animation == "jump":
					velocity.y = JUMP_VELOCITY * 0.66
					anim.play("rise")
					jump_sfx.play()
					set_state.rpc(State.AIR)
			if anim.current_animation == "":
				velocity.y = JUMP_VELOCITY
				anim.play("rise")
				jump_sfx.play()
				set_state.rpc(State.AIR)
			velocity.x = lerpf(velocity.x, 0, 10*delta)
		
		State.AIR:
			move(delta, 2)
			check_for_drop_through()
			check_for_kick()
			check_for_dash()
			check_for_special()
			apply_gravity(delta)

			if velocity.y > 0 && anim.current_animation == "": anim.play("fall")
			if is_on_floor() && velocity.y >= 0: set_state.rpc(State.IDLE)
			elif is_on_wall_only() && sign(velocity.x) == -get_slide_collision(0).get_normal().x: set_state.rpc(State.WALL)

		State.WALL:
			on_wall_prev_frame = true
			check_for_wall_jump()
			velocity.y = lerpf(velocity.y, 0 , 5*delta)
			apply_gravity(delta)
			direction = input.direction.x
			var wall_dir : float = 0
			if get_slide_collision_count() > 0: wall_dir = -get_slide_collision(0).get_normal().x
			wall_jump_dir = wall_dir
			if abs(direction) < dead_zone: direction = 0
			if is_on_wall_only() && sign(direction) != wall_dir && on_wall_prev_frame:
				on_wall_prev_frame = false
				await get_tree().create_timer(0.075).timeout
				if state != State.WALL: return
				set_state.rpc(State.AIR)
			elif !is_on_wall_only() && on_wall_prev_frame:
				on_wall_prev_frame = false
				await get_tree().create_timer(0.075).timeout
				if state != State.WALL: return
				set_state.rpc(State.AIR)

		State.KICK:
			if is_on_floor(): velocity.x = lerpf(velocity.x, 0, 8*delta)
			if input.is_joy_button_pressed(JOY_BUTTON_X) && anim.current_animation == "":
				delta *= 0.1
				if not charged_kick:
					velocity *= 0.1
					sprite.scale = Vector2(1,1)
				charged_kick = true
				apply_gravity(delta)
				sprite.rotation = input.direction.angle()
				if sprite.rotation >= PI/2 || sprite.rotation <= -PI/2:
					sprite.scale = Vector2(1,-1)
				else:
					sprite.scale = Vector2(1,1)
			elif not input.is_joy_button_pressed(JOY_BUTTON_X) && anim.current_animation == "":
				anim.play("kick")
				if not charged_kick: return
				var tween = create_tween()
				tween.tween_property(self, "velocity", velocity * 10, 0.1)
			elif not input.is_joy_button_pressed(JOY_BUTTON_X) && anim.current_animation == "kick_charge":
				anim.play("kick")
				charged_kick = false
			elif anim.current_animation == "kick" || anim.current_animation == "kick_charge":
				apply_gravity(delta)
				move(delta, 2)

		State.DASH:
			check_for_kick()
			if Engine.get_physics_frames() % 3: return
			var after_image : Sprite2D = Sprite2D.new()
			after_image.texture = sprite.texture
			after_image.hframes = sprite.hframes
			after_image.frame = sprite.frame
			after_image.scale = sprite.scale
			after_image.rotation = sprite.rotation + rotation
			after_image.global_position = global_position
			var tween = after_image.create_tween()
			get_tree().root.add_child(after_image)
			after_image.modulate = self_modulate
			tween.tween_property(after_image, "self_modulate", Color(1,1,1, self_modulate.a), 0.1)
			tween.tween_callback(after_image.queue_free)

		State.STALL:
			var anim_finished = (anim.current_animation == "")
			apply_gravity(delta)
			velocity = velocity.lerp(Vector2.ZERO, 10*delta)
			if anim_finished && not is_ball_stalled: set_state.rpc(State.AIR) # set the state to air to avoid coyote time
			if ball_holder.get_child_count() < 1 && is_ball_stalled:
				set_state.rpc(State.AIR)
				return
			var ball : Ball = ball_holder.get_child(0)
			if is_ball_stalled && ball.velocity.length() > 0:
				ball.stalled = false
				ball.set_deferred("disabled", false)
				ball.call_deferred("reparent", get_parent())
				set_state.rpc(State.AIR)
				return
			if not is_ball_stalled: return
			if not anim_finished: return
			var kick_pressed = input.is_joy_button_pressed(JOY_BUTTON_X)
			if kick_pressed: set_state.rpc(State.STALL_KICK)

		State.STALL_KICK:
			apply_gravity(delta)
			velocity.lerp(Vector2.ZERO, 10*delta)


func exit_state():
	match state:
		State.WALL:
			gravity = BASE_GRAVITY
		State.KICK:
			bonk_box_collider.disabled = false
			sprite.scale.y = 1
			charged_kick = false
		State.STALL:
			set_collision_mask_value(3, true)
			bonk_box_collider.disabled = false
			is_ball_stalled = false
		State.STALL_KICK:
			set_collision_mask_value(3, true)
			bonk_box_collider.disabled = false
			is_ball_stalled = false


func _on_animation_finished(animation):
	match animation:
		"kick":
			set_state.rpc(State.AIR)
			sprite.rotation = 0
			sprite.scale = Vector2(1,1)
		"stall_kick":
			set_state.rpc(State.AIR)


func check_for_special():
	var is_special_pressed = input.is_joy_button_pressed(JOY_BUTTON_B)
	if is_special_pressed:
		set_state.rpc(State.STALL)


# func check_for_jump():
# 	var is_jump_pressed = input.is_joy_button_pressed(JOY_BUTTON_A)
# 	if is_jump_pressed && not j_prev_frame:
# 		if can_jump: set_state.rpc(State.JUMP)
# 		j_prev_frame = true
# 	elif not is_jump_pressed:
# 		j_prev_frame = false


func check_for_jump():
	if input.is_button_just_pressed(JOY_BUTTON_A):
		if can_jump: set_state.rpc(State.JUMP)


func check_for_wall_jump():
	if input.is_button_just_pressed(JOY_BUTTON_A):
		velocity.y = JUMP_VELOCITY
		velocity.x = (JUMP_VELOCITY * wall_jump_dir) * 0.65
		set_state.rpc(State.AIR)
		gravity = BASE_GRAVITY
		j_prev_frame = true
	

func check_for_kick():
	if input.is_button_just_pressed(JOY_BUTTON_X):
		set_state.rpc(State.KICK)


var dash_pressed_prev_frame : bool = false
func check_for_dash():
	if input.is_button_just_pressed(JOY_BUTTON_RIGHT_SHOULDER) && dashes > 0:
		dashes -= 1
		set_state.rpc(State.DASH)


func move(delta : float, accel : float = ACCEL, speed : float = SPEED):
	direction = input.direction.x
	if abs(direction) < dead_zone: direction = 0
	if velocity.x: sprite.scale.x = sign(velocity.x)
	velocity.x = lerpf(velocity.x, direction * speed, accel*delta)
	return direction
	

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta


func check_for_drop_through():
	var threshold : float = 0.85
	if input.direction.y > threshold && not is_on_floor():
		set_collision_mask_value(4, false)
	elif input.direction.y > threshold && is_on_floor():
		set_collision_mask_value(4, false)
		velocity.y = 10
	else:
		set_collision_mask_value(4, true)


@rpc("any_peer", "call_local", "reliable")
func launch_stalled_ball():
	is_ball_stalled = false
	var ball : Ball = ball_holder.get_child(0)
	if not ball: return
	var dir = Vector2( input.direction.x, input.direction.y )
	ball.velocity = Vector2(100,0).rotated(dir.angle())
	ball.stalled = false
	ball.reparent(get_parent())
	ball.update_color(self_modulate, controller_index)


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball:Ball):
	if ball.owner_index == -1:
		ball.owner_index = controller_index


func _on_stall_box_body_entered(ball : Ball) -> void:
	is_ball_stalled = true
	apply_ball_ownership.rpc(ball)
	ball.velocity = Vector2.ZERO
	ball.spin = 0
	ball.stalled = true
	ball.global_position = ball_holder.global_position
	ball.reparent(ball_holder)
