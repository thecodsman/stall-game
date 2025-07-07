extends Area2D

@export var player : Player
var player_index : int = -1

func _ready():
	player_index = owner.player_index


func _on_body_entered(ball:Ball) -> void:
	rpc("bonk", ball.get_path())


@rpc("authority", "call_local", "reliable")
func bonk(ball_path : NodePath) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	apply_ball_ownership(ball_path)
	var velocity : Vector2
	var angle = (global_position - ball.global_position).angle()
	if angle >= 0   && angle < PI/2: velocity = Vector2(-20,-60)
	elif angle > PI/2 && angle <= PI: velocity = Vector2(20,-60)
	elif angle > -PI/2 && angle <= 0: velocity = Vector2(-60,20)
	elif angle >= -PI && angle < -PI/2: velocity = Vector2(60,20)
	ball.velocity = velocity
	owner.velocity.x += ball.spin * 85


@rpc("authority", "call_local", "reliable")
func apply_ball_ownership(ball_path : NodePath):
	var ball : Ball = get_node(ball_path)
	if not ball || UI.game_text.visible: return
	if ball.owner_level != 0: return
	if ball.owner_index != player.player_index && ball.owner_level > 0:
		ball.owner_level -= 1
	else:
		ball.owner_index = player.player_index
		ball.owner_level += 1
		if ball.owner_level > Ball.MAX_OWNER_LEVEL: ball.owner_level = Ball.MAX_OWNER_LEVEL
	ball.update_color(player.self_modulate, player.player_index)
