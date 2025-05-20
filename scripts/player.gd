class_name Player extends CharacterBody2D

@export var player_index : int = 0
@export var dead_zone : float = 0.09
const SPEED : float = 100.0
const ACCEL : float = 20.0
const JUMP_VELOCITY : float = -230.0
const BASE_GRAVITY : float = 700.0
const FRICTION : float = 20
const COYOTE_TIME : float = 0.065
var gravity : float = BASE_GRAVITY
var direction : float = 0
var dir_prev_frame : float = 0
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
var run_dash_timer : Timer = Timer.new()
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var bonk_box_collider = $Sprite2D/bonk_box/CollisionShape2D
@onready var jump_sfx = $jump_sfx

enum State {
	IDLE,
	WALK,
	RUN,
	RUN_DASH,
	JUMP,
	AIR,
	KICK,
	WALL,
	DASH
	}
var state : State


func _ready():
	add_child(run_dash_timer)
	anim.animation_finished.connect(_on_animation_finished)


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
			velocity.x = sign(direction) * SPEED*1.2
			run_dash_timer.start(0.15)
			await run_dash_timer.timeout
			if state != State.RUN_DASH: return
			set_state(State.RUN)
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
		State.WALL:
			can_jump = true
			dashes = 1
			gravity = BASE_GRAVITY*0.1
			jump_type = JumpType.WALL


var turned_around : bool = false
func update_state(delta : float):
	match state:
		State.IDLE:
			direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
			velocity.x = lerpf(velocity.x, 0, 10*delta)
			check_for_jump()
			check_for_drop_through()
			check_for_kick()
			apply_gravity(delta)
			if abs(direction) < dead_zone: direction = 0
			if direction:
				await get_tree().create_timer(0.02).timeout
				if abs(direction) > 0.5: set_state(State.RUN_DASH)
				else: set_state(State.WALK)
			if not is_on_floor():
				await get_tree().create_timer(COYOTE_TIME).timeout
				set_state(State.AIR)
			else:
				dashes = 1
				can_jump = true

		State.WALK:
			if not move(delta, ACCEL, SPEED * 0.65): set_state(State.IDLE)
			check_for_jump()
			check_for_drop_through()
			check_for_kick()
			if not is_on_floor():
				await get_tree().create_timer(COYOTE_TIME).timeout
				set_state(State.AIR)
			else:
				dashes = 1
				can_jump = true
			apply_gravity(delta)

		State.RUN:
			direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
			if abs(direction) < dead_zone: direction = 0
			if not direction && abs(velocity.x) < 1: set_state(State.IDLE)
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
			if not is_on_floor():
				await get_tree().create_timer(0.1).timeout
				set_state(State.AIR)
			else:
				dashes = 1
				can_jump = true
			apply_gravity(delta)

		State.RUN_DASH:
			#move(delta, 10)
			direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
			if abs(direction) < dead_zone: direction = 0
			check_for_jump()
			if direction:
				velocity.x = lerpf(velocity.x, direction * SPEED, ACCEL*0.5*delta)
			if not direction * -sprite.scale.x > 0.9 || not abs(dir_prev_frame) < 0.7: return
			sprite.scale.x = sign(direction)
			anim.play("run_dash")
			velocity.x = sign(direction) * SPEED*1.5
			run_dash_timer.start(0.15)

		State.JUMP:
			var is_jump_pressed = Input.is_joy_button_pressed(player_index, JOY_BUTTON_A)
			if is_jump_pressed:
				if not j_prev_frame && can_jump:
					j_prev_frame = true
			elif j_prev_frame && can_jump:
				if anim.current_animation == "jump":
					velocity.y = JUMP_VELOCITY * 0.66
					anim.play("rise")
					jump_sfx.play()
					set_state(State.AIR)
				j_prev_frame = false
			velocity.x = lerpf(velocity.x, 0, 10*delta)
		
		State.AIR:
			move(delta, 2)
			check_for_drop_through()
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
			if is_on_wall_only() && sign(direction) != wall_dir && on_wall_prev_frame:
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
			if is_on_floor(): velocity.x = lerpf(velocity.x, 0, 8*delta)
			if Input.is_joy_button_pressed(player_index, JOY_BUTTON_X) && anim.current_animation == "":
				delta *= 0.1
				if not charged_kick:
					velocity *= 0.1
					sprite.scale = Vector2(1,1)
				charged_kick = true
				apply_gravity(delta)
				sprite.rotation = Vector2(Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X), Input.get_joy_axis(player_index, JOY_AXIS_LEFT_Y)).angle()
				if sprite.rotation > PI/2 || sprite.rotation < -PI/2:
					sprite.scale = Vector2(1,-1)
				else:
					sprite.scale = Vector2(1,1)
			elif not Input.is_joy_button_pressed(player_index, JOY_BUTTON_X) && anim.current_animation == "":
				anim.play("kick")
				if charged_kick:
					var tween = create_tween()
					tween.tween_property(self, "velocity", velocity * 10, 0.1)
			elif not Input.is_joy_button_pressed(player_index, JOY_BUTTON_X) && anim.current_animation == "kick_charge":
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
			after_image.modulate = modulate
			tween.tween_property(after_image, "modulate", Color(1,1,1, modulate.a), 0.1)
			tween.tween_callback(after_image.queue_free)


func exit_state():
	match state:
		State.WALL:
			gravity = BASE_GRAVITY
		State.KICK:
			bonk_box_collider.disabled = false
			sprite.scale.y = 1
			charged_kick = false


func _on_animation_finished(animation):
	match animation:
		"kick":
				set_state(State.AIR)
				sprite.rotation = 0
				sprite.scale = Vector2(1,1)


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


func move(delta : float, accel : float = ACCEL, speed : float = SPEED):
	direction = Input.get_joy_axis(player_index, JOY_AXIS_LEFT_X)
	if abs(direction) < dead_zone: direction = 0
	if velocity.x: sprite.scale.x = sign(velocity.x)
	velocity.x = lerpf(velocity.x, direction * speed, accel*delta)
	return direction
	

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta


func check_for_drop_through():
	var threshold : float = 0.85
	if Input.get_joy_axis(player_index, JOY_AXIS_LEFT_Y) > threshold && not is_on_floor():
		set_collision_mask_value(4, false)
	elif Input.get_joy_axis(player_index, JOY_AXIS_LEFT_Y) > threshold && is_on_floor():
		set_collision_mask_value(4, false)
		velocity.y = 10
	else:
		set_collision_mask_value(4, true)
