extends Area2D

var player_index : int = -1

func _ready():
	player_index = owner.player_index

func _on_body_entered(ball:Ball) -> void:
	if ball.last_hit == -1: ball.last_hit = player_index
	ball.velocity = bonk(ball.global_position)
	owner.velocity.x += ball.spin * 100


func bonk(pos) -> Vector2: ## pass in the global position of the bonked
	var velocity : Vector2
	var angle = (global_position - pos).angle()
	if angle >= 0   && angle < PI/2: velocity = Vector2(-20,-60)
	elif angle > PI/2 && angle <= PI: velocity = Vector2(20,-60)
	elif angle > -PI/2 && angle <= 0: velocity = Vector2(-60,20)
	elif angle >= -PI && angle < -PI/2: velocity = Vector2(60,20)
	return velocity
