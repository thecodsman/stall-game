class_name Ball extends CharacterBody2D

var gravity : float = 70
var owner_index : int = -1 ## player index of the owner of the ball
var owner_level : int = 0 ## level of ownership
var owner_color : Color 
const MaxOwnerLevel : int = 2
var spin : float = 0
var colliding_prev_frame : bool = false
@onready var rotate_node = $rotate_node
@onready var scale_node = $rotate_node/scale_node
@onready var sprite = $rotate_node/scale_node/Sprite2D
@onready var bounce_sfx = $bounce_sfx

func _physics_process(delta : float) -> void:
	if owner_index != -1: velocity.y += gravity * delta
	var raw_vel = velocity
	sprite.rotation += (spin * delta) * 20
	spin = lerpf(spin, 0, 0.5*delta)
	velocity = velocity.rotated((spin * delta))
	juice_it_up()
	move_and_slide()
	if owner_level > 2: owner_level = 2
	for i in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		if not collision: return
		var collider : TileMapLayer = collision.get_collider()
		var tile : TileData = collider.get_cell_tile_data(collider.get_coords_for_body_rid((collision.get_collider_rid())))
		if is_on_floor_only():
			bounce(raw_vel,collision)
			if not tile.get_custom_data("floor"): continue
			if not owner_level > 1: continue
			if GameText.visible: continue
			GameText.visible = true
			GameText.text = str("P", owner_index + 1, " Won!")
			await get_tree().create_timer(2).timeout
			GameText.visible = false
			get_tree().reload_current_scene()
		else:
			bounce(raw_vel,collision)
	colliding_prev_frame = get_slide_collision_count() > 0


func bounce(raw_vel, collision):
	velocity = raw_vel.bounce(collision.get_normal().rotated(clampf(spin*0.25, -PI/2,PI/2)))
	if not colliding_prev_frame:
		spin *= -0.75
		bounce_sfx.volume_linear = raw_vel.length() * 0.1
		bounce_sfx.play()
		velocity *= 0.60


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


func update_color(color : Color, index : int):
	if index != owner_index: color = owner_color
	else: owner_color = color
	match owner_level:
		0:
			modulate = Color.WHITE
		1:
			modulate = color * 1.75
		2:
			modulate = color
