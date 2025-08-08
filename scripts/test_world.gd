extends Node2D

@export var player : Player
@export var ball : Ball

func _ready() -> void:
	Globals.camera.players.append(player)
	Globals.camera.ball = ball
	
