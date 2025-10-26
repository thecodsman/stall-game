class_name Stage extends Node2D

@export  var thumb_nail    : Texture2D
@export  var stage_name    : String
@export  var stage_size    : Vector2       = Vector2(96, 96)
@onready var player_spawns : Array[Node2D] = [$p1_spawn, $p2_spawn, $p3_spawn, $p4_spawn]
@onready var ball_spawn    : Node2D        = $ball_spawn
var player_scene      : PackedScene = preload("res://stuff/player.tscn")
var ball_scene        : PackedScene = preload("res://stuff/bal.tscn")
var score_line_scene  : PackedScene = preload("res://stuff/score_line.tscn")
var score_line_height : float
var round_number      : int
var is_game_point     : bool


func _ready() -> void:
	UI.in_game.show()
	UI.hide_element(UI.scores)
	UI.hide_element(UI.bal_meter)
	UI._on_bal_percent_change(1)
	UI.update_scores(Globals.scores)
	Globals.stage = self
	Lobby.player_loaded.rpc()
	Lobby.player_disconnected.connect(_on_player_disconnected)
	if Globals.is_online == false:
		local_spawn_players()
		start_next_round()


func start_game() -> void: # is only called in online lobbies
	online_spawn_players()
	online_show_ui.rpc()
	start_next_round.rpc()


func spawn_score_line() -> void:
	if is_multiplayer_authority() == false: return
	var score_line : ScoreLine = score_line_scene.instantiate()
	score_line.global_position.y = stage_size.y - score_line_height
	Globals.score_line = score_line
	$SubViewportContainer/game.add_child(score_line, true)
	score_line.height = score_line_height
	score_line.active_line.set_point_position(1, Vector2(stage_size.x, 0))
	score_line.inactive_line.set_point_position(1, Vector2(stage_size.x, 0))
	while score_line.label.get_rect().size.x < stage_size.x + score_line.text_width:
		score_line.label.text += score_line.active_text + "    "
		await get_tree().process_frame


func spawn_ball() -> void:
	if not is_multiplayer_authority(): return
	var ball : Ball = ball_scene.instantiate()
	ball.stage_size      = stage_size
	ball.server          = Globals.get_serving_player()
	ball.global_position = ball_spawn.global_position
	score_line_height    = ball.SCORE_LINE_HEIGHT
	$SubViewportContainer/game.add_child(ball, true)
	set_camera_target_ball.rpc(ball.get_path())
	ball.outline = true
	ball.outline_color = Globals.current_player_colors[Globals.serving_player]
	ball.set_server.rpc(ball.server)


@rpc("authority", "call_local", "reliable")
func set_camera_target_ball(ball_path : NodePath) -> void:
	Globals.camera.ball = get_node(ball_path)


@rpc("authority", "call_local", "reliable")
func set_camera_target_player(player_path : NodePath) -> void:
	Globals.camera.players.append(get_node(player_path))


@rpc("authority", "call_local", "reliable")
func online_show_ui() -> void:
	for i : int in range(Lobby.players.size()):
		var point_display      : HBoxContainer    = UI.point_displays[i]
		var portrait_material  : ShaderMaterial   = point_display.portrait.material
		var output_color_array : PackedColorArray = [Globals.current_player_colors[i]]
		point_display.show()
		portrait_material.set_shader_parameter("output_palette_array", output_color_array)
		point_display.portrait.modulate = Globals.current_player_colors[i]



func online_spawn_players() -> void:
	if not multiplayer.is_server(): return
	for i : int in range(Lobby.players.size()):
		var player : Player = player_scene.instantiate()
		var id     : int    = Lobby.players.keys()[i]
		player.id               = id
		player.name             = str(id)
		player.self_modulate    = Globals.current_player_colors[i]
		player.player_index     = i + 1
		player.controller_index = 0
		player.stage_size       = stage_size
		$SubViewportContainer/game.add_child(player, true)
		player.set_location.rpc_id(id, player_spawns[i].global_position)
		set_camera_target_player.rpc(player.get_path())


func local_spawn_players() -> void:
	for i : int in range(Globals.registered_controllers.size()):
		var player             : Player           = player_scene.instantiate()
		var device             : int              = Globals.registered_controllers[i]
		var point_display      : HBoxContainer    = UI.point_displays[i]
		var portrait_material  : ShaderMaterial   = point_display.portrait.material
		var output_color_array : PackedColorArray = [Globals.current_player_colors[i]]
		point_display.show()
		portrait_material.set_shader_parameter("output_palette_array", output_color_array)
		point_display.portrait.modulate = Globals.current_player_colors[i]
		player.id               = 1
		player.name             = str(device)
		player.self_modulate    = Globals.current_player_colors[i]
		player.player_index     = i + 1
		player.controller_index = device
		player.stage_size       = stage_size
		$SubViewportContainer/game.add_child(player)
		player.global_position = player_spawns[i].global_position
		Globals.camera.players.append(player)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventJoypadButton: return
	if not event.button_index == JOY_BUTTON_START: return
	pause()


func pause() -> void:
	UI.pause_menu.show()
	get_tree().paused = true


@rpc("authority", "call_local", "reliable")
func start_next_round() -> void:
	if Globals.camera.ball: Globals.camera.ball.queue_free()
	if Globals.scores.has(Globals.points_to_win - 1): is_game_point = true
	else: is_game_point = false
	round_number += 1
	UI.hide_element(UI.scores)
	UI.show_element(UI.game_text)
	UI.game_text.text = "ROUND %s" % round_number
	if is_game_point:
		await get_tree().create_timer(1).timeout
		UI.game_text.text = "GAME POINT"
		Globals.camera.screen_shake(10, 2, 2)
	await get_tree().create_timer(1).timeout
	UI.game_text.text = "READY?"
	await get_tree().create_timer(1).timeout
	UI.game_text.text = "GO!"
	Globals.camera.screen_shake(10, 2, 2)
	await get_tree().create_timer(0.5).timeout
	UI.hide_element(UI.game_text)
	UI.show_element(UI.bal_meter)
	spawn_ball()
	if not Globals.score_line: spawn_score_line()


func _on_player_disconnected(id : int) -> void:
	for i : int in range(Globals.camera.players.size()):
		var player : Player = Globals.camera.players[i]
		if player.name != str(id): continue
		Globals.camera.players.remove_at(i)
		Globals.current_player_colors.remove_at(i)
		player.queue_free()
		break
	
