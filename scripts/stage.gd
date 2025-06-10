class_name Stage extends Node2D

@export var thumb_nail : Texture2D
@export var stage_name : String
var player_scene = preload("res://stuff/player.tscn")
@onready var player_spawns : Array[Node2D] = [$p1_spawn, $p2_spawn]


func _ready():
	if Globals.is_online: Lobby.player_loaded.rpc()
	else: start_game()


func start_game():
	if Globals.is_online: online_spawn_players()
	else: local_spawn_players()


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

