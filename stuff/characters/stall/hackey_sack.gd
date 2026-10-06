class_name HackeySack
extends CharacterBody2D

@export var active_gravity : float = 0.05
@export var inactive_gravity : float = 1
@export var bounce_factor : float = 0.6
@export var air_drag : float = 0.5
@export var active_spin_drag : float = 0.5
@export var inactive_spin_drag : float = 2
@export var power : float = 25
@export var visible_spin_mult : float = 20
@export var max_active_time : float
@export var max_inactive_time : float
@export var arming_time : float
@export var active_time_till_blinky : float = 12
@export var inactive_time_till_blinky : float = 1.5
@onready var hitbox : HitBox = $HitBox
@onready var hurtbox : HurtBox = $HurtBox
@onready var sprite_r : Node2D = $rotate_node
@onready var sprite_s : Node2D = $rotate_node/scale_node
@onready var sprite : Sprite2D = $rotate_node/scale_node/Sprite2D
var spin : float = 0
var arming_timer : Timer = Timer.new()
var active_timer : Timer = Timer.new()
var destroy_timer : Timer = Timer.new()
var blinky_timer : Timer = Timer.new()
var blinky_tween : Tween
var is_active : bool = true :
	set(active):
		is_active = active
		if active:
			hitbox.active = true
			hurtbox.active = true
			hurtbox.apply_knockback = true
			hurtbox.hit_fx = true
			sprite_r.rotation = 0
			sprite_s.scale = Vector2(1, 1)
			destroy_timer.stop()
			if blinky_tween: blinky_tween.kill()
			blinky_timer.start(active_time_till_blinky)
			active_timer.start()
			sprite.show()
			if player: modulate = Globals.current_player_colors[player.player_index - 1]
		else:
			hitbox.active = false
			hurtbox.apply_knockback = false
			hurtbox.hit_fx = false
			modulate = Globals.GRAY
			destroy_timer.start()
			if blinky_tween: blinky_tween.kill()
			sprite.show()
			blinky_timer.start(inactive_time_till_blinky)
var player : Player :
	set(_player):
		if not hitbox:
			await ready
		player = _player
		hitbox.player = player


func _ready() -> void:
	modulate = Globals.GRAY
	spin = randf_range(-1, 1)
	destroy_timer.one_shot = true
	destroy_timer.wait_time = max_inactive_time
	destroy_timer.timeout.connect(_on_destroy_timer_timeout)
	add_child(destroy_timer)
	blinky_timer.one_shot = true
	blinky_timer.wait_time = inactive_time_till_blinky
	blinky_timer.timeout.connect(_on_blinky_timer_timeout)
	add_child(blinky_timer)
	active_timer.one_shot = true
	active_timer.wait_time = max_active_time
	active_timer.timeout.connect(_on_active_timer_timeout)
	add_child(active_timer)
	arming_timer.one_shot = true
	arming_timer.wait_time = arming_time
	add_child(arming_timer)
	arming_timer.start()
	await arming_timer.timeout
	is_active = true


func _physics_process(delta: float) -> void:
	sprite.rotation += spin * delta * visible_spin_mult
	var raw_vel : Vector2 = velocity
	if is_active:
		velocity.y += active_gravity * delta
		spin = lerpf(spin, 0, active_spin_drag * delta)
	else:
		velocity.y += inactive_gravity * delta
		spin = lerpf(spin, 0, inactive_spin_drag * delta)
		if is_on_floor():
			sprite_s.scale = sprite_s.scale.lerp(Vector2(1.5, 0.75), 4 * delta)
			sprite_r.rotation = 0
		else:
			var width  : float = clampf(velocity.length() * 0.035, 1, 2)
			var height : float = 1/width
			sprite_s.scale = Vector2(width, height)
			sprite_r.rotation = velocity.angle()
	velocity = velocity.lerp(Vector2.ZERO, air_drag * delta)
	move_and_slide()
	for i : int in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		if not collision: return
		bounce(raw_vel, collision)


func bounce(raw_vel : Vector2, collision : KinematicCollision2D) -> void:
	if raw_vel.length() > 5:
		velocity = raw_vel.bounce(collision.get_normal())
		velocity *= bounce_factor


func _on_hurt_box_hurt(hit: HitBox) -> void:
	if "spin" in hit.owner:
		spin = hit.owner.spin
	if hit.owner is Ball and is_active:
		await get_tree().physics_frame
		is_active = false
	elif hit.owner is Player and not is_active and hit.owner == player:
		hurtbox.apply_knockback = true
		hurtbox.hit_fx = true
		await get_tree().physics_frame
		is_active = true


func _on_destroy_timer_timeout() -> void:
	player.hackeys_out -= 1
	queue_free()


func _on_blinky_timer_timeout() -> void:
	blinky_tween = create_tween().set_loops()
	blinky_tween.tween_callback(sprite.hide).set_delay(0.1)
	blinky_tween.tween_callback(sprite.show).set_delay(0.1)


func _on_active_timer_timeout() -> void:
	is_active = false
