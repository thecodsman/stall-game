extends Node2D

@export var player : Player
@export var ball : Ball
var stage_height : float = 96
var score_line : float

func _ready() -> void:
	Globals.camera.players.append(player)
	Globals.camera.ball = ball
	score_line = ball.SCORE_LINE_HEIGHT
