class_name BlockBox extends Node2D

signal blocked(ball : Ball)

@export var player : Player
@export var block_power : float
@export var collider : CollisionShape2D


func _on_body_entered(obj:Node2D) -> void:
	if obj is Ball:
		handle_ball_collision(obj)


func handle_ball_collision(ball : Ball) -> void:
	if ball.server != null: return ## if the ball is not in play dont do anything
	blocked.emit(ball)
	if not is_multiplayer_authority(): return
	block_ball.rpc(ball.get_path())


@rpc("authority", "call_local", "reliable")
func block_ball(ball_path : NodePath) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	apply_ball_ownership(ball_path)
	ball.set_state(ball.State.NORMAL)
	ball.velocity = Vector2(block_power, 0).rotated(rotation)
	ball.spin = 0


@rpc("any_peer", "call_local", "reliable")
func apply_ball_ownership(ball_path : NodePath) -> void:
	var ball : Ball = get_node(ball_path)
	if not ball: return
	if ball.owner_level > 1 and ball.owner_index != player.player_index:
		ball.owner_level = 1
		ball.scorrable = false
		ball.update_color()
		Globals.score_line.deactivate()


func _on_visibility_changed() -> void:
	collider.set_deferred("disabled", !visible)
