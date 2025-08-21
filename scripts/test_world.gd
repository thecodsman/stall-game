extends Node2D

@export var player : Player
@export var ball : Ball
@export var score_line_scene : PackedScene
@export var stage_size : Vector2 = Vector2(96,96)
var score_line_height : float

func _ready() -> void:
	spawn_score_line()
	ball.stage_height = stage_size.y
	Globals.camera.players.append(player)
	Globals.camera.ball = ball


func spawn_score_line() -> void:
	var score_line : ScoreLine = score_line_scene.instantiate()
	score_line_height = ball.SCORE_LINE_HEIGHT
	score_line.global_position.y = stage_size.y - score_line_height
	Globals.score_line = score_line
	$SubViewportContainer/game.add_child(score_line)
	score_line.active_line.set_point_position(1, Vector2(stage_size.x, 0))
	score_line.inactive_line.set_point_position(1, Vector2(stage_size.x, 0))
	while score_line.label.get_rect().size.x < stage_size.x + score_line.text_width:
		score_line.label.text += score_line.active_text + "    "
		await get_tree().process_frame
