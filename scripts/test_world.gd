extends Node2D

@export var players : Array[Player]
@export var ball : Ball
@export var score_line_scene : PackedScene
@export var stage_size : Vector2 = Vector2(96,96)
var score_line_height : float

func _ready() -> void:
	spawn_score_line()
	ball.stage_size = stage_size
	for i : int in range(players.size()):
		var player : Player = players[i]
		player.stage_size = stage_size
		Globals.current_player_colors = [player.self_modulate]
	Globals.camera.players.append(players)
	Globals.camera.ball = ball
	UI.hide()


func spawn_score_line() -> void:
	var score_line : ScoreLine = score_line_scene.instantiate()
	score_line_height = ball.SCORE_LINE_HEIGHT
	score_line.global_position.y = stage_size.y - score_line_height
	Globals.score_line = score_line
	$SubViewportContainer/game.add_child(score_line)
	score_line.active_line.set_point_position(1, Vector2(stage_size.x, 0))
	score_line.inactive_line.set_point_position(1, Vector2(stage_size.x, 0))
	score_line.visible = false
	while score_line.label.get_rect().size.x < stage_size.x + score_line.text_width:
		score_line.label.text += score_line.active_text + "    "
		await get_tree().process_frame
