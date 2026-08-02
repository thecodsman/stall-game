extends Camera2D

@export var min_zoom     : Vector2 = Vector2(1,1)
@export var max_zoom     : Vector2 = Vector2(1,1)
@export var inner_margin : Vector2 = Vector2(20, 20) ## margin for zoom-in/camera lock
@export var outer_margin : Vector2 = Vector2(10, 10) ## margin for zoom-out/camera move
var centering : bool  = false
var shaket    : int   = 0
var shakei    : float = 0
var shakef    : int   = 1 ## shake every X amount of frames
var players   : Array[Player]
var ball      : Ball


func _ready() -> void:
	Globals.camera = self


func _physics_process(delta : float) -> void:
	_apply_screen_shake()
	if players.is_empty(): return
	var screen_size : Vector2 = Vector2(90,90)
	var player_distance2center : Vector2
	var player_distance2edge   : Vector2 = Vector2.INF
	var player_group_center_point : Vector2 = Vector2.ZERO
	for i : int in range(players.size()):
		var player           : Player  = players[i]
		var _distance2center : Vector2 = player.get_screen_transform().origin - (get_viewport_rect().size/2)
		var _distance2edge   : Vector2 = screen_size/2 - abs(_distance2center)
		player_distance2center = player_distance2center.max(_distance2center)
		player_distance2edge = player_distance2edge.min(_distance2edge)
		player_group_center_point += player.global_position
	player_group_center_point /= players.size()
	var zoom_direction : int = 0 ## zooming out is -1 and zooming in is 1
	if minf(player_distance2edge.x, player_distance2edge.y) < 0 and zoom > min_zoom:
		zoom_direction = -1
	if player_distance2edge < outer_margin and zoom >= min_zoom:
		centering = true
	elif player_distance2edge > outer_margin && zoom > Vector2(1,1):
		zoom_direction = 1
	elif player_distance2center < inner_margin && zoom < max_zoom:
		centering = false
		zoom_direction = 1
	else:
		zoom_direction = 0
	if centering:
		global_position = global_position.move_toward(player_group_center_point, 125*delta)
	match zoom_direction:
		-1:
			if player_distance2edge < outer_margin * 0.75:
				zoom = zoom.lerp(min_zoom, 6*delta)
		1:
			if abs(player_distance2center) < inner_margin * 0.75:
				zoom = zoom.lerp(Vector2(1,1), 6*delta)


@rpc("authority", "call_remote", "unreliable")
func screen_shake(frames : int, intensity : float, frequency : int = 1) -> void:
	shaket = frames
	shakei = intensity
	shakef = frequency
	if is_multiplayer_authority() == false: return
	screen_shake.rpc(frames, intensity, frequency)


func _apply_screen_shake() -> void:
	if Engine.get_physics_frames() % shakef: return
	if shaket > 0:
		offset  = Vector2(randf_range(-shakei,shakei),randf_range(-shakei,shakei))
		shaket -= 1
	else:
		offset = Vector2.ZERO
