class_name Stage extends Node2D

@export var thumb_nail : Texture2D
@export var stage_name : String

func _ready():
	Lobby.player_loaded.rpc()
