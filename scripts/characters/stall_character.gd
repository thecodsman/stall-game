class_name StallCharacter extends Player

@export var SLIDE_SPEED : float = 100.0
@export var MAX_SLIDE_BOOST_SPEED : float = 300.0
var slide_boost_strength : float = 0
var is_ball_stalled : bool = false
var ball : Ball
@onready var ball_holder : Node2D = $Sprite2D/ball_holder
@onready var bonk_box_collider : CollisionShape2D = $Sprite2D/bonk_box/CollisionShape2D
@onready var stall_box : Area2D = $Sprite2D/stall_box

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

enum Jump {
	NORMAL,
	SUPER,
	HYPER,
	ULTRA,
	}
var jump : Jump


@rpc("any_peer", "call_local", "reliable") # any peer so the host can set peers settings
func set_location(pos : Vector2) -> void:
	global_position = pos


func _enter_tree() -> void:
	if Globals.is_online:
		var _id : int = int(name)
		set_multiplayer_authority(_id)
		input.set_multiplayer_authority(_id)
	else:
		set_multiplayer_authority(1)
	$server_sync.set_multiplayer_authority(1)


func _ready() -> void:
	sprite.self_modulate = self_modulate
	kick_box.hit.connect(_on_hit)
	input.device_index = controller_index
	#process_state = (get_multiplayer_authority() == multiplayer.get_unique_id())


func _physics_process(_delta: float) -> void:
	if in_water && abs(angle_difference(input.direction.angle(), PI/2)) < PI/4:
		gravity = WATER_GRAVITY * 6
	elif in_water && abs(angle_difference(input.direction.angle(), PI/2)) > PI/4:
		gravity = WATER_GRAVITY
	anim.speed_scale = time_scale
	var prev_velocity : Vector2 = velocity
	velocity *= time_scale
	move_and_slide()
	if time_scale:
		velocity /= time_scale
	else:
		velocity = prev_velocity
	global_position.x = fposmod(global_position.x, stage_size.x)
	global_position.y = fposmod(global_position.y, stage_size.y)


func move(delta : float, accel : float = ACCEL, speed : float = RUN_SPEED, flip : bool = true) -> float:
	direction = input.direction.x
	velocity.x = lerpf(velocity.x, direction * speed, accel*delta)
	var facing_direction : float = sign(velocity.x)
	if velocity.x && flip == true && facing_direction != 0: sprite.scale.x = facing_direction
	return facing_direction
	

func apply_gravity(delta : float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _anim_launch_stalled_ball() -> void:
	if not ball || not is_multiplayer_authority(): return
	launch_stalled_ball.rpc(ball.get_path())


@rpc("authority", "call_local", "reliable")
func launch_stalled_ball(ball_path : NodePath) -> void:
	ball = get_node(ball_path)
	if not ball: return
	is_ball_stalled = false
	ball.velocity = Vector2(0,-100)
	ball.update_color(self_modulate, player_index)
	ball.set_state(ball.State.NORMAL)
	

func apply_ball_ownership(ball_path : NodePath) -> void:
	ball = get_node(ball_path)
	if not ball || Globals.round_ending: return
	if ball.owner_index != player_index:
		ball.owner_level = abs(ball.owner_level - 2)
		ball.owner_index = player_index
		ball.scorrable = false
		Globals.score_line.deactivate.rpc()
	elif ball.owner_index == player_index:
		ball.owner_level = 2
		ball.scorrable = false
	if ball.owner_level > Ball.MAX_OWNER_LEVEL: ball.owner_level = Ball.MAX_OWNER_LEVEL
	ball.update_color(self_modulate, player_index)


func _on_stall_box_body_entered(_ball : Ball) -> void:
	if _ball.server != self && _ball.server != null: return
	ball = _ball
	if ball.stalled || not is_multiplayer_authority(): return
	stall_ball.rpc(ball.get_path())


func _on_hit(obj : Node2D) -> void:
	if obj is Ball:
		handle_ball_hit(obj)
	elif obj is Player:
		handle_player_hit(obj)


func handle_ball_hit(_ball : Ball) -> void:
	const freeze_frame_duration_mult : float = 0.001
	time_scale = 0
	_ball.time_scale = 0
	dashes = max(1,dashes)
	jumps = max(1,jumps)
	var duration : float = freeze_frame_duration_mult * kick_box.power * _ball.damage
	sprite.shake(1, duration, 1)
	_ball.sprite.shake(2, duration, 2)
	await get_tree().create_timer(duration).timeout
	time_scale = 1
	if not _ball: return
	_ball.time_scale = 1


func handle_player_hit(_player : Player) -> void:
	const freeze_frame_duration_mult : float = 0.001
	time_scale = 0
	_player.time_scale = 0
	dashes = max(1,dashes)
	jumps = max(1,jumps)
	var duration : float = freeze_frame_duration_mult * kick_box.power
	sprite.shake(1, duration, 1)
	_player.sprite.shake(2, duration, 2)
	await get_tree().create_timer(duration).timeout
	time_scale = 1
	if not _player: return
	_player.time_scale = 1


@rpc("authority", "call_local", "reliable")
func stall_ball(ball_path : NodePath) -> void:
	ball = get_node(ball_path)
	if not ball || ball.stalled: return
	ball.set_state(ball.State.NORMAL) # makes it so you can put someone into quantum superposition by stalling the ball they are stalling
	var stall_box_collider : CollisionShape2D = stall_box.get_child(0)
	stall_box_collider.set_deferred("disabled", true)
	ball.velocity = Vector2.ZERO
	ball.set_state(ball.State.STALLED)
	ball.staller = self
	is_ball_stalled = true
	ball.global_position = ball_holder.global_position
	apply_ball_ownership(ball_path)


@rpc("authority", "call_local", "unreliable")
func spawn_smoke(pos : Vector2 = Vector2(0, 4)) -> void:
	var smoke_scene : PackedScene = preload("res://particles/smoke.tscn")
	var smoke : GPUParticles2D = smoke_scene.instantiate()
	add_child(smoke)
	smoke.emitting = true
	smoke.process_material.direction.x = sign(velocity.x)
	smoke.position = pos
	await smoke.finished
	smoke.queue_free()


@rpc("authority", "call_local", "unreliable")
func spawn_afterimage(time : float = 0.1) -> void:
	var after_image : Sprite2D = Sprite2D.new()
	after_image.texture = sprite.texture
	after_image.hframes = sprite.hframes
	after_image.frame = sprite.frame
	after_image.scale = sprite.scale
	after_image.rotation = sprite.rotation + rotation
	after_image.global_position = global_position
	var tween : Tween = after_image.create_tween()
	get_parent().add_child(after_image)
	after_image.modulate = self_modulate
	tween.tween_property(after_image, "self_modulate", Color(1,1,1, self_modulate.a), time)
	tween.tween_callback(after_image.queue_free)


@rpc("authority", "call_local", "unreliable")
func spawn_spark(pos : Vector2) -> void:
	var spark_scene : PackedScene = preload("res://particles/spark.tscn")
	var spark : Node2D = spark_scene.instantiate()
	spark.global_position = global_position + pos
	get_parent().add_child(spark)


func _on_water_detector_water_entered() -> void:
	gravity = WATER_GRAVITY
	air_accel = WATER_ACCEL
	air_friction = WATER_FRICTION
	air_speed = WATER_SPEED
	in_water = true


func _on_water_detector_water_exited() -> void:
	gravity = BASE_GRAVITY
	air_accel = AIR_ACCEL
	air_friction = AIR_FRICTION
	air_speed = AIR_SPEED
	in_water = false
