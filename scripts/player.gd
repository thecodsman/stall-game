class_name Player extends CharacterBody2D

@export var player_index : int = 0
@export var dead_zone : float = 0.09
const SPEED : float = 100.0
const JUMP_VELOCITY : float = -200.0
const BASE_GRAVITY : float = 700.0
var gravity : float = BASE_GRAVITY
var direction : float = 0
var can_jump : bool = false
var j_prev_frame : bool = false
var jump_buffered : bool = false
var jump_buffer_timer : Timer = Timer.new()
var dash_speed : float = 200.0
var dashes : int = 1
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

enum State {
	IDLE,
	RUN,
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
	if jump_buffered && can_jump:
		if is_on_floor(): velocity.y = JUMP_VELOCITY
		elif is_on_wall_only(): 
			velocity.y = JUMP_VELOCITY
			velocity.x = JUMP_VELOCITY * -get_slide_collision(0).get_normal().x
		can_jump = false
		anim.play("jump")
		set_state(State.AIR)
		jump_buffered = false
		jump_buffer_timer.stop()

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
			set_state(State.IDLE)
		State.AIR:
			can_jump = false
		State.WALL:
			can_jump = true
			dashes = 1
			velocity.y = clampf(velocity.y, -5,5)
			gravity = BASE_GRAVITY*0.25


func update_state(delta : float):
	match state:
		State.IDLE:
			direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
			velocity.x = move_toward(velocity.x, 0, SPEED)
			check_for_jump()
			check_for_kick()
			apply_gravity(delta)
			if abs(direction) < dead_zone: direction = 0
			if not is_on_floor(): set_state(State.AIR)
			else:
				dashes = 1
				can_jump = true
			check_for_dash()
			if direction: set_state(State.RUN)

		State.RUN:
			if not move(delta): set_state(State.IDLE)
			check_for_jump()
			check_for_kick()
			check_for_dash()
			if not is_on_floor(): set_state(State.AIR)
			else:
				dashes = 1
				can_jump = true
			apply_gravity(delta)
		
		State.AIR:
			move(delta, 5)
			check_for_jump()
			check_for_kick()
			check_for_dash()
			apply_gravity(delta)

			if velocity.y > 0 && anim.current_animation != "fall": anim.play("fall")
			if is_on_floor() && velocity.y >= 0: set_state(State.IDLE)
			elif is_on_wall_only() && sign(velocity.x) == -get_slide_collision(0).get_normal().x: set_state(State.WALL)

		State.WALL:
			check_for_jump()
			gravity = BASE_GRAVITY * 0.1
			apply_gravity(delta)
			if !is_on_wall_only(): set_state(State.IDLE)

		State.KICK:
			apply_gravity(delta)
			if not anim.current_animation: set_state(State.IDLE)
			if is_on_floor(): velocity.x = move_toward(velocity.x, 0, SPEED)

		State.DASH:
			if Engine.get_physics_frames() % 3: return
			var after_image : Sprite2D = Sprite2D.new()
			after_image = sprite.duplicate()
			after_image.global_position = global_position
			var tween = after_image.create_tween()
			get_tree().root.add_child(after_image)
			after_image.modulate = modulate
			tween.tween_property(after_image, "modulate", Color(modulate.r, modulate.g, modulate.b, 0), 0.1)


func exit_state():
	match state:
		State.WALL:
			gravity = BASE_GRAVITY


func check_for_jump():
	if Input.is_joy_button_pressed(player_index, JOY_BUTTON_A):
		if not j_prev_frame:
			jump_buffered = true
			jump_buffer_timer.start()
		j_prev_frame = true
		gravity = BASE_GRAVITY
	elif velocity.y < 0:
		j_prev_frame = false
		gravity = BASE_GRAVITY * 4
	else:
		j_prev_frame = false
		gravity = BASE_GRAVITY


func check_for_kick():
	if Input.is_joy_button_pressed(player_index, JOY_BUTTON_X):
		anim.play("kick")
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
