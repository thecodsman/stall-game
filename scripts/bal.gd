class_name Ball extends CharacterBody2D

var gravity : float = 70
var last_hit : int = -1
@onready var rotate_node = $rotate_node
@onready var scale_node = $rotate_node/scale_node
@onready var sprite = $rotate_node/scale_node/Sprite2D

func _physics_process(delta : float) -> void:
	if last_hit != -1: velocity.y += gravity * delta
	var raw_vel = velocity
	sprite.rotation += velocity.length() * delta * 0.1
	juice_it_up()
	move_and_slide()
	for i in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Player:
			last_hit = collider.player_index
			punt(collider.global_position)
		elif is_on_floor():
			if GameText.visible: return
			GameText.visible = true
			GameText.text = str("P", last_hit + 1, " Won!")
			await get_tree().create_timer(2).timeout
			GameText.visible = false
			get_tree().reload_current_scene()
			velocity = raw_vel.bounce(collision.get_normal())
			velocity *= 0.90
			return
		else:
			velocity = raw_vel.bounce(collision.get_normal())
			velocity *= 0.90


func punt(pos): ## pass in the global position of the punter
	# Camera.screen_shake(4,5)
	var angle = (pos - global_position).angle()
	if angle >= 0   && angle < PI/2: velocity = Vector2(-20,-60)
	elif angle > PI/2 && angle <= PI: velocity = Vector2(20,-60)
	elif angle > -PI/2 && angle <= 0: velocity = Vector2(-60,20)
	elif angle >= -PI && angle < -PI/2: velocity = Vector2(60,20)
	

var prev_vel : Vector2 = Vector2.ZERO
var prev_scale : Vector2 = Vector2(1,1)

func juice_it_up():
	var width : float = clampf(velocity.length() * 0.01, 1, 2)
	var height : float = 1/width
	var angle : float = wrapf(velocity.angle(), -PI/2, PI/2)
	if get_slide_collision_count() > 0 && prev_vel.length() > 20: 
		width = prev_scale.y
		height = prev_scale.x
		scale_node.scale = Vector2(width,height)
		rotate_node.rotation = angle
		if velocity.length() > 90:
			Globals.freeze_frame(0.05)
			Globals.camera.screen_shake(velocity.length() * 0.05, velocity.length() * 0.02, 5)
		prev_vel = velocity
		prev_scale = Vector2(width,height)
		return
	scale_node.scale = Vector2(width,height)
	rotate_node.rotation = angle
	prev_vel = velocity
	prev_scale = Vector2(width,height)
