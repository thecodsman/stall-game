class_name Ball extends CharacterBody2D

var gravity : float = 70
var owner_index : int = -1 ## player index of the owner of the ball
var owner_level : int = 0 ## level of ownership
var owner_color : Color 
var spin : float = 0
var colliding_prev_frame : bool = false
var stalled : bool = false
const MAX_OWNER_LEVEL : int = 2
@onready var rotate_node := $rotate_node
@onready var scale_node := $rotate_node/scale_node
@onready var sprite := $rotate_node/scale_node/Sprite2D
@onready var bounce_sfx := $bounce_sfx
@onready var collision_shape : CollisionShape2D = $CollisionShape2D


func _enter_tree():
	set_multiplayer_authority(1)


func _ready():
	set_physics_process(multiplayer.get_unique_id() == 1)


func _physics_process(delta : float) -> void:
	var raw_vel = velocity
	if owner_level > 2: owner_level = 2
	sprite.rotation += (spin * delta) * 20
	spin = lerpf(spin, 0, 0.5*delta)
	velocity = velocity.rotated((spin * delta))
	juice_it_up()
	if stalled: return
	if owner_index != -1: velocity.y += gravity * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		if not collision: return
		var collider : TileMapLayer = collision.get_collider()
		var tile : TileData = collider.get_cell_tile_data(collider.get_coords_for_body_rid((collision.get_collider_rid())))
		if is_on_floor_only():
			bounce(raw_vel,collision)
			#rpc("force_update_ownership", owner_index, owner_level)
			if tile.get_custom_data("floor") && is_multiplayer_authority(): rpc("end_game", owner_index)
		else:
			bounce(raw_vel,collision)
	colliding_prev_frame = get_slide_collision_count() > 0


@rpc("authority", "call_local", "reliable")
func end_game(winner : int):
	if owner_level < MAX_OWNER_LEVEL: return
	if GameText.visible: return
	var tree : SceneTree = null
	GameText.text = str("P%s Won!" % winner)
	GameText.visible = true
	if not is_inside_tree():
		await tree_entered
		tree = get_tree()
	else:
		tree = get_tree()
	await tree.create_timer(2).timeout
	GameText.visible = false
	tree.reload_current_scene()


func bounce(raw_vel, collision):
	velocity = raw_vel.bounce(collision.get_normal().rotated(clampf(spin*0.25, -PI/2,PI/2)))
	if not colliding_prev_frame:
		spin *= -0.75
		bounce_sfx.volume_linear = raw_vel.length() * 0.1
		bounce_sfx.play()
		velocity *= 0.60


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


@rpc("any_peer", "call_local", "reliable")
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


@rpc("authority", "call_remote", "reliable")
func force_update_ownership(index, level):
	owner_level = level
	owner_index = index
