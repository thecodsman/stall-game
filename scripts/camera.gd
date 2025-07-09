extends Camera2D

@export var min_zoom : Vector2 = Vector2(1,1)
@export var max_zoom : Vector2 = Vector2(1,1)
@export var inner_margin : int = 20 ## margin for zoom-in/camera lock
@export var outer_margin : int = 10 ## margin for zoom-out/camera move
var centering : bool = false
var shaket : int = 0
var shakei : float = 0
var shakef : int = 1 ## shake every X amount of frames
var players : Array[Player]
var ball : Ball


func _ready():
	Globals.camera = self


func _physics_process(delta : float):
	_apply_screen_shake()
	if not ball || players.is_empty(): return
	var screen_size : Vector2 = Vector2(96,96)
	var ball_distance2center = ball.get_screen_transform().origin - (screen_size/2)
	var ball_distance2edge = screen_size/2 - abs(ball_distance2center)
	if ball_distance2edge.x < outer_margin:
		global_position.x = global_position.move_toward(ball.global_position, ball.velocity.length() * delta).x
		centering = true
	elif centering:
		global_position.x = global_position.move_toward(ball.global_position, ball.velocity.length() * delta).x
	elif abs(ball_distance2center.x) < inner_margin:
		centering = false
	var player_distance2center : Vector2
	var player_distance2edge : Vector2 = Vector2.INF
	for i in range(players.size()):
		var player = players[i]
		var _distance2center = player.get_screen_transform().origin - (get_viewport_rect().size/2)
		var _distance2edge = screen_size/2 - abs(_distance2center)
		player_distance2center = player_distance2center.max(_distance2center)
		player_distance2edge = player_distance2edge.min(_distance2edge)
	var zoom_direction : int = 0 ## zooming out is -1 and zooming in is 1
	if player_distance2edge.x < outer_margin && zoom != min_zoom:
		zoom_direction = -1
	elif abs(player_distance2center.x) < inner_margin && zoom != Vector2(1,1):
		zoom_direction = 1
	else:
		zoom_direction = 0
	match zoom_direction:
		-1:
			if player_distance2edge.x < outer_margin * 0.75:
				zoom = zoom.lerp(min_zoom, 6*delta)
		1:
			if abs(player_distance2center.x) < inner_margin * 0.75:
				zoom = zoom.lerp(Vector2(1,1), 6*delta)


func screen_shake(frames : int, intensity : float, frequency : int = 1):
	shaket = frames
	shakei = intensity
	shakef = frequency


func _apply_screen_shake():
	if Engine.get_physics_frames() % shakef: return
	if shaket > 0:
		offset = Vector2(randf_range(-shakei,shakei),randf_range(-shakei,shakei))
		shaket -= 1
	else:
		offset = Vector2.ZERO
