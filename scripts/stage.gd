class_name Stage extends Node2D

@export var thumb_nail : Texture2D
@export var stage_name : String
var player_scene = preload("res://stuff/player.tscn")
@onready var player_spawns : Array[Node2D] = [$p1_spawn, $p2_spawn]


func _ready():
	Lobby.player_loaded.rpc()


func start_game():
	online_spawn_players()


func online_spawn_players():
	for i in range(Lobby.players.size()):
		var player : Player = player_scene.instantiate()
		player.set_multiplayer_authority.rpc(Lobby.players.keys()[i])
		player.name = str(Lobby.players.keys()[i])
		player.self_modulate = Globals.player_colors[i]
		player.player_index = i + 1
		print(i + 1)
		player.controller_index = 0
		$SubViewportContainer/game.add_child(player)
		player.global_position = player_spawns[i].global_position
