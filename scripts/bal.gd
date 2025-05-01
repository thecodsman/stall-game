class_name Ball extends CharacterBody2D

var gravity : float = 70
var last_hit : int = -1
@onready var sprite = $Sprite2D

func _physics_process(delta : float) -> void:
	if last_hit != -1: velocity.y += gravity * delta
	var raw_vel = velocity
	sprite.rotation += velocity.length() * delta * 0.1
	move_and_slide()
	for i in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Player:
			last_hit = collider.player_index
			print(collider)
			punt(collider.global_position)
		else:
			velocity = raw_vel.bounce(collision.get_normal())
			velocity *= 0.70


func punt(pos): ## pass in the global position of the punter
	var angle = (pos - global_position).angle()
	if angle >= 0   && angle < PI/2: velocity = Vector2(-20,-60)
	elif angle > PI/2 && angle <= PI: velocity = Vector2(20,-60)
	elif angle > -PI/2 && angle <= 0: velocity = Vector2(-60,20)
	elif angle >= -PI && angle < -PI/2: velocity = Vector2(60,20)
	
