class_name Player extends CharacterBody2D

@export var player_index : int = 0
@export var dead_zone : float = 0.09
const SPEED : float = 100.0
const JUMP_VELOCITY : float = -200.0
const BASE_GRAVITY : float = 700.0
const FRICTION : float = 20
var gravity : float = BASE_GRAVITY
var direction : float = 0
var can_jump : bool = false
var j_prev_frame : bool = false
var jump_buffered : bool = false
var jump_buffer_timer : Timer = Timer.new()
enum JumpType {
	FULL,
	SHORT,
	WALL
	}
var jump_type : JumpType
var wall_jump_dir : float = 0
var dash_speed : float = 200.0
var dashes : int = 1
var on_wall_prev_frame : bool = false
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var bonk_box_collider = $Sprite2D/bonk_box/CollisionShape2D

enum State {
	IDLE,
	RUN,
	JUMP,
	AIR,
	KICK,
	WALL,
	DASH
	}
var state : State


func _ready():
	add_child(jump_buffer_timer)
	jump_buffer_timer.one_shot = true
	jump_buffer_timer.wait_time = 0.1
	jump_buffer_timer.timeout.connect(func():
		jump_buffered = false
		)


func _physics_process(delta: float) -> void:
	if Input.is_joy_button_pressed(player_index, JOY_BUTTON_Y):
		if player_index == 0: queue_free()
		else: global_position = Vector2(48,48)
	update_state(delta)
	move_and_slide()


func set_state(new_state : State):
	if state == new_state: return
	exit_state()
	state = new_state
	enter_state()


func enter_state():
	match state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
		State.DASH:
			anim.play("dash")
			var dir = Vector2(Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(player_index, JOY_AXIS_LEFT_Y))
			velocity = dir * dash_speed
			await get_tree().create_timer(0.1).timeout
			set_state(State.AIR)
		State.JUMP:
			anim.play("jump")
			await anim.animation_finished
			if not Input.is_joy_button_pressed(player_index, JOY_BUTTON_A): return
			velocity.y = JUMP_VELOCITY
			anim.play("rise")
			set_state(State.AIR)
		State.AIR:
			#await get_tree().create_timer(0.1).timeout
			can_jump = false
		State.KICK:
			anim.play("kick_charge")
			bonk_box_collider.disabled = true
			await anim.animation_finished
			var tween = create_tween()
			tween.tween_property(self, "velocity", Vector2.ZERO, 0.2)
			sprite.scale = Vector2(1,1)
			#velocity *= 0
		State.WALL:
			can_jump = true
			dashes = 1
			#velocity.y = clampf(velocity.y, -5,5)
			gravity = BASE_GRAVITY*0.1
			jump_type = JumpType.WALL


func update_state(delta : float):
	match state:
		State.IDLE:
			direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
			velocity.x = lerpf(velocity.x, 0, 10*delta)
			check_for_drop_through()
			check_for_jump()
			check_for_kick()
			apply_gravity(delta)
			if abs(direction) < dead_zone: direction = 0
			if direction: set_state(State.RUN)
			if not is_on_floor():
				await get_tree().create_timer(0.1).timeout
				set_state(State.AIR)
			else:
				dashes = 1
				can_jump = true

		State.RUN:
			if not move(delta): set_state(State.IDLE)
			check_for_drop_through()
			check_for_jump()
			check_for_kick()
			if not is_on_floor():
				await get_tree().create_timer(0.1).timeout
				set_state(State.AIR)
			else:
				dashes = 1
				can_jump = true
			apply_gravity(delta)

		State.JUMP:
			var is_jump_pressed = Input.is_joy_button_pressed(player_index, JOY_BUTTON_A)
			if is_jump_pressed:
				if not j_prev_frame && can_jump:
					j_prev_frame = true
			elif j_prev_frame && can_jump:
				if anim.current_animation == "jump":
					velocity.y = JUMP_VELOCITY * 0.75
					anim.play("rise")
					set_state(State.AIR)
				j_prev_frame = false
			velocity.x = lerpf(velocity.x, 0, 10*delta)
		
		State.AIR:
			move(delta, 2)
			check_for_jump()
			check_for_kick()
			check_for_dash()
			apply_gravity(delta)

			if velocity.y > 0 && anim.current_animation == "": anim.play("fall")
			if is_on_floor() && velocity.y >= 0: set_state(State.IDLE)
			elif is_on_wall_only() && sign(velocity.x) == -get_slide_collision(0).get_normal().x: set_state(State.WALL)

		State.WALL:
			on_wall_prev_frame = true
			check_for_wall_jump()
			velocity.y = lerpf(velocity.y, 0 , 5*delta)
			apply_gravity(delta)
			direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
			var wall_dir : float = 0
			if get_slide_collision_count() > 0: wall_dir = -get_slide_collision(0).get_normal().x
			wall_jump_dir = wall_dir
			if abs(direction) < dead_zone: direction = 0
			if is_on_wall_only() && round(direction) != wall_dir && on_wall_prev_frame:
				on_wall_prev_frame = false
				await get_tree().create_timer(0.075).timeout
				if state != State.WALL: return
				set_state(State.AIR)
			elif !is_on_wall_only() && on_wall_prev_frame:
				on_wall_prev_frame = false
				await get_tree().create_timer(0.075).timeout
				if state != State.WALL: return
				set_state(State.AIR)

		State.KICK:
			if Input.is_joy_button_pressed(player_index, JOY_BUTTON_X) && anim.current_animation == "":
				apply_gravity(delta/10)
				sprite.rotation = Vector2(Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(player_index, JOY_AXIS_LEFT_Y)).angle()
				if sprite.rotation > PI/2 || sprite.rotation < -PI/2:
					sprite.scale.y = -1
				else:
					sprite.scale = Vector2(1,1)
			elif not Input.is_joy_button_pressed(player_index, JOY_BUTTON_X) && anim.current_animation == "":
				anim.play("kick")
				await anim.animation_finished
				set_state(State.IDLE)
				sprite.rotation = 0
				sprite.scale = Vector2(1,1)
			elif not Input.is_joy_button_pressed(player_index, JOY_BUTTON_X) && anim.current_animation == "kick_charge":
				anim.play("kick")
				await anim.animation_finished
				set_state(State.IDLE)
			if is_on_floor(): velocity.x = move_toward(velocity.x, 0, SPEED)
			elif anim.current_animation == "kick_charge": apply_gravity(delta)
			elif anim.current_animation == "kick": apply_gravity(delta)

		State.DASH:
			if Engine.get_physics_frames() % 3: return
			var after_image : Sprite2D = Sprite2D.new()
			after_image.texture = sprite.texture
			after_image.hframes = sprite.hframes
			after_image.frame = sprite.frame
			after_image.global_position = global_position
			var tween = after_image.create_tween()
			get_tree().root.add_child(after_image)
			after_image.modulate = modulate
			tween.tween_property(after_image, "modulate", Color(1,1,1, modulate.a), 0.1)
			tween.tween_callback(after_image.queue_free)


func exit_state():
	match state:
		State.WALL:
			gravity = BASE_GRAVITY
		State.KICK:
			bonk_box_collider.disabled = false


func check_for_jump():
	var is_jump_pressed = Input.is_joy_button_pressed(player_index, JOY_BUTTON_A)
	if is_jump_pressed && not j_prev_frame:
		if can_jump: set_state(State.JUMP)
		j_prev_frame = true
	elif not is_jump_pressed:
		j_prev_frame = false


func check_for_wall_jump():
	var is_jump_pressed = Input.is_joy_button_pressed(player_index, JOY_BUTTON_A)
	if is_jump_pressed && not j_prev_frame:
		velocity.y = JUMP_VELOCITY
		velocity.x = (JUMP_VELOCITY * wall_jump_dir) * 0.65
		set_state(State.AIR)
		gravity = BASE_GRAVITY
		j_prev_frame = true
	elif not is_jump_pressed:
		j_prev_frame = false
	

func check_for_kick():
	if Input.is_joy_button_pressed(player_index, JOY_BUTTON_X):
		set_state(State.KICK)


var dash_pressed_prev_frame : bool = false
func check_for_dash():
	if Input.is_joy_button_pressed(player_index, JOY_BUTTON_RIGHT_SHOULDER) && not dash_pressed_prev_frame && dashes > 0:
		dash_pressed_prev_frame = true
		dashes -= 1
		set_state(State.DASH)
	elif not Input.is_joy_button_pressed(player_index, JOY_BUTTON_RIGHT_SHOULDER):
		dash_pressed_prev_frame = false


func move(delta : float, accel : float = 20):
	direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
	if abs(direction) < dead_zone: direction = 0
	if direction:
		velocity.x = lerpf(velocity.x, direction * SPEED, accel*delta)
		sprite.scale.x = sign(direction)
	return direction
	

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta


func check_for_drop_through():
	if Input.get_joy_axis(player_index, JOY_AXIS_LEFT_Y) > 0.9 && is_on_floor():
		set_collision_mask_value(4, false)
		velocity.y += 5
		return true
	else:
		set_collision_mask_value(4, true)
		return false
