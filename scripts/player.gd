class_name Player extends CharacterBody2D

@export_category("movement")
@export var SPEED : float = 100.0
@export var DASH_SPEED : float = 200.0
@export var SLIDE_SPEED : float = 100.0
@export var MAX_SLIDE_BOOST_SPEED : float = 300.0
@export var ACCEL : float = 20.0
@export var AIR_ACCEL : float = 8.0
@export var FULL_JUMP_VELOCITY : float = -200
@export var BACKFLIP_VELOCITY : float = -300
@export var SHORT_JUMP_VELOCITY : float = -150
@export var BASE_GRAVITY : float = 700.0
@export var FRICTION : float = 20
@export var COYOTE_TIME : float = 0.05
@export var MAX_JUMPS : int = 2
@export_category("misc")
@export var player_index : int = 0
@export var controller_index : int = 0
@export var id : int = 1
var gravity : float = BASE_GRAVITY
var direction : float = 0
var dir_prev_frame : float = 0
var jumps = MAX_JUMPS
var can_jump : bool = false
var slide_boost_strength : float = 0
var wall_jump_dir : float = 0
var dashes : int = 1
var on_wall_prev_frame : bool = false
var run_dash_timer : Timer = Timer.new()
var is_ball_stalled : bool = false
var process_state : bool = false
var ball : Ball
@onready var input : PlayerInput = $Input
@onready var ball_holder : Node2D = $Sprite2D/ball_holder
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var bonk_box_collider : CollisionShape2D = $Sprite2D/bonk_box/CollisionShape2D
@onready var kick_collider : CollisionShape2D = $Sprite2D/kick_box/CollisionShape2D
@onready var kick_box : KickBox = $Sprite2D/kick_box
@onready var jump_sfx : AudioStreamPlayer = $jump_sfx
@onready var stall_box : Area2D = $Sprite2D/stall_box

enum State {
	IDLE,
	WALK,
	CROUCH,
	RUN,
	INITIAL_SPRINT,
	TURN_AROUND,
	JUMP,
	BACKFLIP,
	AIR,
	LANDING,
	ATTACK,
	SLIDE_KICK,
	WALL,
	DASH,
	STALL,
	STALL_KICK
	}
var state : State
var prev_state : State

enum Attack {
	NAIR,
	BAIR,
	UPAIR,
	FAIR,
	DAIR,
	UP,
	NEUTRAL,
	SIDE,
	DOWN,
	DASH
	}
var attack : Attack

@rpc("any_peer", "call_local", "reliable") # any peer so the host can set peers settings
func set_location(pos : Vector2):
	global_position = pos


func _enter_tree():
	if Globals.is_online:
		var _id = int(name)
		set_multiplayer_authority(_id)
	else:
		set_multiplayer_authority(1)
	$server_sync.set_multiplayer_authority(1)


func _ready():
	sprite.self_modulate = self_modulate
	add_child(run_dash_timer)
	anim.animation_finished.connect(_on_animation_finished)
	input.device_index = controller_index
	process_state = (get_multiplayer_authority() == multiplayer.get_unique_id())


func _physics_process(delta: float) -> void:
	if process_state: update_state(delta)
	move_and_slide()


@rpc("any_peer", "call_local", "unreliable_ordered")
func set_state(new_state : State):
	if state == new_state: return
	exit_state()
	prev_state = state
	state = new_state
	enter_state()


var charged_kick : bool = false
func enter_state():
	match state:
		State.IDLE:
			anim.play("idle")
			slide_boost_strength = 0
			if not is_on_floor(): set_state.rpc(State.AIR) ## DONT DO COYOTE TIME WHEN SETTING STATE TO IDLE

		State.WALK:
			anim.play("walk")

		State.RUN:
			anim.play("run")

		State.CROUCH:
			anim.play("crouch")

		State.INITIAL_SPRINT:
			anim.play("run_dash")
			spawn_smoke(Vector2(0,4))
			velocity.x += sign(direction) * SPEED
			sprite.scale.x = sign(velocity.x)

		State.TURN_AROUND:
			anim.play("turn_around")
			spawn_smoke(Vector2(0,4))

		State.DASH:
			anim.play("dash")
			velocity = input.direction * DASH_SPEED
			await get_tree().create_timer(0.1).timeout
			if state != State.DASH: return
			set_state.rpc(State.AIR)

		State.JUMP:
			anim.play("jump")

		State.BACKFLIP:
			anim.play("jump")

		State.LANDING:
			anim.play("landing")
			slide_boost_strength = 1
			jumps = MAX_JUMPS
			dashes = 1

		State.ATTACK:
			var input_dir : float = (input.direction * Vector2(sprite.scale.x, 1)).angle()
			if prev_state == State.RUN || prev_state == State.INITIAL_SPRINT:
				attack = Attack.DASH
				kick_box.direction = Vector2(0.6,-0.4)
				kick_box.power = 60
			elif is_on_floor():
				if input.direction.length() <= input.NeutralZone:
					attack = Attack.NEUTRAL
					kick_box.direction = Vector2.from_angle(-0.261)
					kick_box.power = 45
				elif input_dir > PI * 0.25 && input_dir < PI * 0.75: # slide kick
					attack = Attack.DOWN
					kick_box.direction = Vector2.UP
					kick_box.power = 60
				elif input_dir < -PI * 0.25 && input_dir > -PI * 0.75:
					attack = Attack.UP
					kick_box.direction = Vector2.UP
					kick_box.power = 30
				else:
					attack = Attack.SIDE
					kick_box.direction = Vector2(0.8,-0.2)
					kick_box.power = 75
			else:
				if input.direction.length() <= input.NeutralZone:
					attack = Attack.NAIR
					kick_box.direction = Vector2.ZERO
					kick_box.power = 60
				elif input_dir > PI * 0.25 && input_dir < PI * 0.75:
					attack = Attack.DAIR
					kick_box.direction = Vector2.DOWN
					kick_box.power = 80
				elif input_dir < PI * -0.25 && input_dir > PI * -0.75:
					attack = Attack.UPAIR
					kick_box.direction = Vector2.UP
					kick_box.power = 60
				elif input_dir >= PI * -0.25 && input_dir <= PI * 0.25:
					attack = Attack.FAIR
					kick_box.power = 70
					kick_box.direction = Vector2(0.9,-0.1)
				elif input_dir >= PI * 0.75 || input_dir <= PI * -0.75:
					attack = Attack.BAIR
					kick_box.power = 100
					kick_box.direction = Vector2(-0.8,0.2)
			# -----
			match attack:
				Attack.NEUTRAL:
					anim.play("neutral_attack")
				Attack.UP:
					anim.play("up_attack")
				Attack.SIDE:
					anim.play("side_attack")
				Attack.DOWN:
					anim.play("down_attack")
					kick_box.direction = Vector2.UP
					kick_collider.set_deferred("disabled", false)
					if slide_boost_strength > 0:
						velocity.x += MAX_SLIDE_BOOST_SPEED * slide_boost_strength * sprite.scale.x
						slide_boost_strength = 0
					else:
						velocity.x += SLIDE_SPEED * sprite.scale.x
				Attack.DASH:
					const DASH_ATTACK_SPEED_BOOST : float = 120
					anim.play("dash_attack")
					velocity.x = DASH_ATTACK_SPEED_BOOST * sprite.scale.x
				Attack.UPAIR:
					anim.play("upair")
				Attack.NAIR:
					anim.play("nair")
				Attack.DAIR:
					anim.play("dair")
				Attack.BAIR:
					anim.play("bair")
				Attack.FAIR:
					anim.play("fair")

		State.SLIDE_KICK:
			kick_box.direction = Vector2.UP
			kick_box.power = 100.0
			kick_collider.set_deferred("disabled", false)
			velocity.x += 100 * sprite.scale.x

		State.WALL:
			anim.play("on_wall")
			jumps = MAX_JUMPS
			dashes = 1
			gravity = BASE_GRAVITY*0.1

		State.STALL:
			anim.play("stall")
			set_collision_mask_value(3, false)
			is_ball_stalled = (ball != null)

		State.STALL_KICK:
			anim.play("stall_kick")
			set_collision_mask_value(3, false)


func update_state(delta : float):
	match state:
		State.IDLE:
			direction = input.direction.x
			velocity.x = lerpf(velocity.x, 0, 10*delta)
			apply_gravity(delta)
			var side_input : bool = (((input.direction).angle() > -PI*0.25 && input.direction.angle() < PI*0.25) || (input.direction.angle() > PI*0.75 || input.direction.angle() < -PI*0.75))
			if input.just_smashed() && side_input:
				set_state.rpc(State.INITIAL_SPRINT)
			elif direction && side_input:
				set_state.rpc(State.WALK)
			if not is_on_floor():
				await get_tree().create_timer(COYOTE_TIME).timeout
				jumps -= 1
				set_state.rpc(State.AIR)
			else:
				dashes = 1
				jumps = MAX_JUMPS
			check_for_jump()
			check_for_drop_through()
			check_for_attack()
			check_for_special()
			check_for_crouch()

		State.WALK:
			if not move(delta, ACCEL, SPEED * 0.65): set_state.rpc(State.IDLE)
			if not is_on_floor():
				await get_tree().create_timer(COYOTE_TIME).timeout
				set_state.rpc(State.AIR)
			else:
				dashes = 1
				jumps = MAX_JUMPS
			if input.just_smashed():
				set_state.rpc(State.INITIAL_SPRINT)
			apply_gravity(delta)
			check_for_jump()
			check_for_drop_through()
			check_for_attack()
			check_for_special()
			check_for_crouch()

		State.CROUCH:
			velocity.x = lerpf(velocity.x, 0, 4*delta)
			if not check_for_crouch(): set_state.rpc(State.IDLE)
			if not is_on_floor(): set_state.rpc(State.AIR)
			check_for_attack()
			check_for_jump()
			check_for_special()
			check_for_drop_through()

		State.RUN:
			direction = input.direction.x
			if not direction && abs(velocity.x) < 10: set_state.rpc(State.IDLE)
			elif sign(direction) == -sprite.scale.x: 
				set_state.rpc(State.TURN_AROUND)
			elif anim.current_animation == "":
				anim.play("run")
				move(delta, ACCEL, SPEED, false)
			elif anim.current_animation == "run":
				move(delta, ACCEL, SPEED, false)
			if not is_on_floor():
				await get_tree().create_timer(COYOTE_TIME).timeout
				set_state.rpc(State.AIR)
			else:
				dashes = 1
				jumps = MAX_JUMPS
			apply_gravity(delta)
			check_for_jump()
			check_for_drop_through()
			check_for_attack()
			check_for_special()
			check_for_crouch()

		State.INITIAL_SPRINT:
			direction = input.direction.x
			var _accel = ACCEL * 0.66
			move(delta, _accel, SPEED, false)
			if anim.current_animation != "run_dash":
				set_state.rpc(State.RUN)
				return
			check_for_jump()
			if check_for_attack(): attack = Attack.DASH
			if not input.just_smashed(): return
			sprite.scale.x = sign(direction)
			anim.play("RESET")
			anim.play("run_dash")
			spawn_smoke(Vector2(0,4))
			velocity.x = sign(direction) * SPEED

		State.TURN_AROUND:
			check_for_backflip()
			check_for_attack()
			velocity.x = lerpf(velocity.x, 0, 10*delta)
			if anim.current_animation == "":
				sprite.scale.x *= -1
				set_state.rpc(State.RUN)

		State.JUMP:
			var is_jump_pressed = input.is_joy_button_pressed(JOY_BUTTON_A)
			if not is_jump_pressed && jumps > 0 && anim.current_animation == "jump":
				velocity.y = SHORT_JUMP_VELOCITY
				anim.play("rise")
				jumps -= 1
				jump_sfx.play()
				set_state.rpc(State.AIR)
			elif anim.current_animation == "" && jumps > 0:
				velocity.y = FULL_JUMP_VELOCITY
				anim.play("rise")
				jump_sfx.play()
				jumps -= 1
				set_state.rpc(State.AIR)
			velocity.x = lerpf(velocity.x, 0, 10*delta)

		State.BACKFLIP:
			if anim.current_animation == "":
				velocity = Vector2(65 * sprite.scale.x, BACKFLIP_VELOCITY)
				set_state.rpc(State.AIR)
				anim.play("backflip")
		
		State.AIR:
			move(delta, 2, SPEED, false)
			check_for_drop_through()
			check_for_attack()
			check_for_dash()
			check_for_jump()
			check_for_special()
			apply_gravity(delta)
			if velocity.y > 0 && anim.current_animation == "": anim.play("fall")
			if is_on_floor() && velocity.y >= 0:
				spawn_smoke.rpc(Vector2(0,4))
				set_state.rpc(State.LANDING)
			elif is_on_wall_only() && sign(velocity.x) == -get_slide_collision(0).get_normal().x: set_state.rpc(State.WALL)

		State.LANDING:
			var landing_friction : float = 7
			slide_boost_strength = lerpf(slide_boost_strength, 0, 30*delta)
			if is_on_floor():
				velocity = velocity.lerp(Vector2.ZERO, landing_friction*delta)
			if anim.current_animation == "":
				set_state.rpc(State.IDLE)
			check_for_attack()
			check_for_jump()

		State.WALL:
			on_wall_prev_frame = true
			check_for_wall_jump()
			velocity.y = lerpf(velocity.y, 0 , 5*delta)
			apply_gravity(delta)
			direction = input.direction.x
			var wall_dir : float = 0
			if get_slide_collision_count() > 0: wall_dir = -get_slide_collision(0).get_normal().x
			wall_jump_dir = wall_dir
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

		State.ATTACK:
			match attack:
				Attack.UP:
					check_for_jump()
					velocity.x = lerpf(velocity.x, 0, 7*delta)
					if not is_on_floor(): set_state.rpc(State.AIR)
				Attack.NEUTRAL:
					check_for_jump()
					velocity.x = lerpf(velocity.x, 0, 7*delta)
					if not is_on_floor(): set_state.rpc(State.AIR)
				Attack.DOWN:
					check_for_jump()
					velocity.x = lerpf(velocity.x, 0, 2*delta)
					if abs(velocity.x) < 20: set_state.rpc(State.IDLE)
					if not is_on_floor(): set_state.rpc(State.AIR)
				Attack.SIDE:
					check_for_jump()
					velocity.x = lerpf(velocity.x, 0, 7*delta)
					if not is_on_floor(): set_state.rpc(State.AIR)
				Attack.DASH:
					velocity.x = lerpf(velocity.x, 0, delta)
					if anim.current_animation == "": set_state.rpc(State.IDLE)
					if not is_on_floor(): set_state.rpc(State.AIR)
				Attack.UPAIR:
					move(delta, AIR_ACCEL, SPEED, false)
					apply_gravity(delta)
					if is_on_floor(): set_state.rpc(State.LANDING)
				Attack.NAIR:
					move(delta, AIR_ACCEL, SPEED, false)
					apply_gravity(delta)
					if is_on_floor(): set_state.rpc(State.LANDING)
				Attack.DAIR:
					move(delta, AIR_ACCEL, SPEED, false)
					apply_gravity(delta)
					if is_on_floor(): set_state.rpc(State.LANDING)
				Attack.BAIR:
					move(delta, AIR_ACCEL, SPEED, false)
					apply_gravity(delta)
					if is_on_floor(): set_state.rpc(State.LANDING)
				Attack.FAIR:
					move(delta, AIR_ACCEL, SPEED, false)
					apply_gravity(delta)
					if is_on_floor(): set_state.rpc(State.LANDING)
			if anim.current_animation == "":
				set_state.rpc(State.IDLE)

		State.SLIDE_KICK:
			check_for_jump()
			velocity.x = lerpf(velocity.x, 0, 2*delta)
			if abs(velocity.x) < 20: set_state.rpc(State.IDLE)

		State.DASH:
			check_for_attack()
			if is_on_floor(): set_state.rpc(State.LANDING)
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
			if anim_finished && not is_ball_stalled: set_state.rpc(State.IDLE)
			if not ball && is_ball_stalled:
				is_ball_stalled = false
				set_state.rpc(State.IDLE)
				return
			if not ball: return
			if (is_ball_stalled && not ball.stalled):
				ball.stalled = false
				is_ball_stalled = false
				ball.collision_shape.set_deferred("disabled", false)
				ball = null
				set_state.rpc(State.IDLE)
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

		State.ATTACK:
			sprite.scale.y = 1
			charged_kick = false
			anim.play("RESET")
			kick_collider.set_deferred("disabled", true)

		State.STALL:
			set_collision_mask_value(3, true)
			is_ball_stalled = false

		State.STALL_KICK:
			set_collision_mask_value(3, true)
			is_ball_stalled = false


func _on_animation_finished(animation):
	match animation:
		"kick":
			set_state.rpc(State.IDLE)
			sprite.rotation = 0
			sprite.scale = Vector2(1,1)
		"stall_kick":
			set_state.rpc(State.IDLE)


func check_for_special():
	var is_special_pressed = input.is_joy_button_pressed(JOY_BUTTON_B)
	if is_special_pressed || ball:
		set_state.rpc(State.STALL)


func check_for_jump():
	if input.is_button_just_pressed(JOY_BUTTON_A):
		if jumps <= 0: return false
		set_state.rpc(State.JUMP)
		return true
	return false


func check_for_crouch():
	if input.direction.angle() < PI * 0.75 && input.direction.angle() > PI * 0.25 && input.neutral:
		set_state.rpc(State.CROUCH)
		return true
	return false

func check_for_backflip():
	if input.is_button_just_pressed(JOY_BUTTON_A):
		if jumps <= 0: return false
		set_state.rpc(State.BACKFLIP)
		return true
	return false


func check_for_wall_jump():
	if input.is_button_just_pressed(JOY_BUTTON_A):
		velocity.y = FULL_JUMP_VELOCITY
		velocity.x = (FULL_JUMP_VELOCITY * wall_jump_dir) * 0.65
		set_state.rpc(State.AIR)
		gravity = BASE_GRAVITY
	

func check_for_attack():
	if input.is_button_just_pressed(JOY_BUTTON_X):
		set_state.rpc(State.ATTACK)
		return true
	return false


func check_for_slide_kick():
	if input.direction.y < 0.9 || not input.is_button_just_pressed(JOY_BUTTON_X): return
	set_state.rpc(State.SLIDE_KICK)


func check_for_dash():
	if input.is_button_just_pressed(JOY_BUTTON_RIGHT_SHOULDER) && dashes > 0:
		dashes -= 1
		set_state.rpc(State.DASH)


func move(delta : float, accel : float = ACCEL, speed : float = SPEED, flip : bool = true):
	direction = input.direction.x
	if velocity.x && flip == true: sprite.scale.x = sign(velocity.x)
	velocity.x = lerpf(velocity.x, direction * speed, accel*delta)
	return direction
	

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta


func check_for_drop_through():
	var threshold : float = 0.85
	if input.direction.y > threshold && not is_on_floor():
		set_collision_mask_value(4, false)
	elif input.just_smashed() && (input.direction.angle() > PI*0.25 && input.direction.angle() < PI*0.75) && is_on_floor():
		set_collision_mask_value(4, false)
		velocity.y = 10
	else:
		set_collision_mask_value(4, true)


func _anim_launch_stalled_ball():
	if not ball || not is_multiplayer_authority(): return
	launch_stalled_ball.rpc(ball.get_path())


@rpc("authority", "call_local", "reliable")
func launch_stalled_ball(ball_path : NodePath):
	ball = get_node(ball_path)
	if not ball: return
	is_ball_stalled = false
	ball.velocity = Vector2(0,-100)
	ball.stalled = false
	ball.staller = null
	ball.collision_shape.set_deferred("disabled", false)
	ball.update_color(self_modulate, player_index)
	ball = null


func apply_ball_ownership(ball_path : NodePath):
	ball = get_node(ball_path)
	if not ball || UI.game_text.visible: return
	if ball.owner_index != player_index:
		ball.owner_level = abs(ball.owner_level - 2)
		ball.owner_index = player_index
	elif ball.owner_index == player_index:
		ball.owner_level = 2
	if ball.owner_level > Ball.MAX_OWNER_LEVEL: ball.owner_level = Ball.MAX_OWNER_LEVEL
	ball.update_color(self_modulate, player_index)


func _on_stall_box_body_entered(_ball : Ball) -> void:
	ball = _ball
	if ball.stalled || not is_multiplayer_authority(): return
	stall_ball.rpc(ball.get_path())


@rpc("authority", "call_local", "reliable")
func stall_ball(ball_path : NodePath):
	ball = get_node(ball_path)
	if not ball || ball.stalled: return
	var stall_box_collider : CollisionShape2D = stall_box.get_child(0)
	stall_box_collider.set_deferred("disabled", true)
	ball.velocity = Vector2.ZERO
	ball.spin = 0
	ball.stalled = true
	ball.staller = self
	is_ball_stalled = true
	ball.global_position = ball_holder.global_position
	ball.collision_shape.set_deferred("disabled", true)
	apply_ball_ownership(ball_path)


@rpc("authority", "call_local", "unreliable")
func spawn_smoke(pos : Vector2 = Vector2(0, 4)):
	var smoke_scene : PackedScene = preload("res://particles/smoke.tscn")
	var smoke : GPUParticles2D = smoke_scene.instantiate()
	add_child(smoke)
	smoke.emitting = true
	smoke.process_material.direction.x = sign(velocity.x)
	smoke.position = pos
	await smoke.finished
	smoke.queue_free()
