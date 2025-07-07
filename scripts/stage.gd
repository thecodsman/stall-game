class_name Stage extends Node2D

@export var thumb_nail : Texture2D
@export var stage_name : String
var player_scene = preload("res://stuff/player.tscn")
var ball_scene = preload("res://stuff/bal.tscn")
@onready var player_spawns : Array[Node2D] = [$p1_spawn, $p2_spawn]
@onready var ball_spawn : Node2D = $ball_spawn


func _ready():
	UI.scores.show()
	UI._on_bal_percent_change(1)
	Lobby.player_loaded.rpc()
	if not Globals.is_online:
		local_spawn_players()
		spawn_ball()


func start_game(): # is only called in online lobbies
	online_spawn_players()
	spawn_ball()


func spawn_ball():
	if not is_multiplayer_authority(): return
	var ball : Ball = ball_scene.instantiate()
	Globals.camera.ball = ball
	ball.global_position = ball_spawn.global_position
	$SubViewportContainer/game.add_child(ball, true)


func online_spawn_players():
	if not multiplayer.is_server(): return
	for i in range(Lobby.players.size()):
		var player : Player = player_scene.instantiate()
		var id = Lobby.players.keys()[i]
		player.id = id
		player.name = str(id)
		player.self_modulate = Globals.player_colors[i]
		player.player_index = i + 1
		player.controller_index = 0
		$SubViewportContainer/game.add_child(player, true)
		player.set_location.rpc_id(id, player_spawns[i].global_position)
		Globals.camera.players.append(player)


func local_spawn_players():
	for i in range(Globals.registered_controllers.size()):
		var player : Player = player_scene.instantiate()
		var device = Globals.registered_controllers[i]
		player.id = 1
		player.name = str(device)
		player.self_modulate = Globals.player_colors[i]
		player.player_index = i + 1
		player.controller_index = device
		$SubViewportContainer/game.add_child(player)
		player.global_position = player_spawns[i].global_position
		Globals.camera.players.append(player)
