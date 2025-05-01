class_name Player extends CharacterBody2D

@export var player_index : int = 0
@export var dead_zone : float = 0.09
const SPEED : float = 150.0
const JUMP_VELOCITY : float = -300.0
const BASE_GRAVITY : float = 900.0
var gravity : float = BASE_GRAVITY
var direction : float = 0
var can_jump : bool = false
var j_prev_frame : bool = false
var jump_buffered : bool = false
var jump_buffer_timer : Timer = Timer.new()


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
		jump_buffered = false
		jump_buffer_timer.stop()

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
	
	direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
	if abs(direction) < dead_zone:
		direction = 0

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	# for i in get_slide_collision_count():
	# 	var collision : KinematicCollision2D = get_slide_collision(i)
	# 	var collider : Node2D = collision.get_collider()
	# 	if not collider is Ball: continue
	# 	if collider.velocity.length() + velocity.length() < 85:
	# 		collider.velocity = Vector2(0,-65)
	move_and_slide()
