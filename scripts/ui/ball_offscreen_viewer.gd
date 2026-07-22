extends Control

@export var max_distance : float
@onready var ball_icon : Sprite2D = %ball_icon
@onready var border : Sprite2D = %border
@onready var path_follow : PathFollow2D = $Path2D/PathFollow2D
var ball_is_onscreen : bool = true


func _physics_process(_delta: float) -> void:
	if not Globals.ball: return
	var ball : Ball = Globals.ball
	var camera : Camera2D = Globals.camera
	var ball_rect : Rect2 = ball.visibility_detector.rect
	var ball_visibility_rect : Rect2 = ball_rect
	var camera_viewport_rect : Rect2 = camera.get_viewport_rect()
	camera_viewport_rect.position = camera.global_position - (camera_viewport_rect.size / 2)
	ball_visibility_rect.position = ball.global_position + ball_rect.position
	ball_is_onscreen = camera_viewport_rect.intersects(ball_visibility_rect)
	if ball_is_onscreen:
		hide()
		return
	show()
	var distance_to_ball : Vector2 = ball.global_position - camera.global_position
	var angle_to_ball : float = distance_to_ball.angle()
	var angle_progress : float = (angle_to_ball + PI) / TAU
	var distance_progress : float = (maxf(distance_to_ball.length(), camera_viewport_rect.size.x) - camera_viewport_rect.size.x) / max_distance
	path_follow.scale = Vector2(1 - distance_progress, 1 - distance_progress)
	path_follow.progress_ratio = angle_progress
