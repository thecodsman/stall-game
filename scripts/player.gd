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
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

enum State {
	IDLE,
	RUN,
	AIR,
	KICK
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
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if jump_buffered && is_on_floor():
		velocity.y = JUMP_VELOCITY
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


func update_state(delta : float):
	match state:
		State.IDLE:
			direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
			velocity.x = move_toward(velocity.x, 0, SPEED)
			check_for_jump()
			check_for_kick()
			if abs(direction) < dead_zone: direction = 0
			if direction: set_state(State.RUN)

		State.RUN:
			check_for_jump()
			check_for_kick()
			if not move(): set_state(State.IDLE)
		
		State.AIR:
			check_for_jump()
			check_for_kick()
			move()

			if velocity.y > 0 && anim.current_animation != "fall": anim.play("fall")
			if is_on_floor() && velocity.y >= 0: set_state(State.IDLE)

		State.KICK:
			if not anim.current_animation: set_state(State.IDLE)
			if is_on_floor(): velocity.x = move_toward(velocity.x, 0, SPEED)


func exit_state():
	pass


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


func move():
	direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
	if abs(direction) < dead_zone: direction = 0
	if direction:
		velocity.x = direction * SPEED
		sprite.scale.x = sign(direction)
	return direction
	
