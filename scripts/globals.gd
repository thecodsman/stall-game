extends Node

signal scores_changed

@export var player_colors : PackedColorArray
@export var available_colors : PackedColorArray
@export var GRAY : Color
@onready var current_player_colors : PackedColorArray
var camera : Camera2D
var is_online : bool = false
var registered_controllers : Array[int] ## array of device ids
var scores : Array[int] = [0, 0, 0, 0] ## scores for the match
var score_line : ScoreLine
var points_to_win : int = 3
var round_ending : bool = false


@rpc("authority", "call_local", "reliable")
func end_round(winner : int) -> void:
	var tree : SceneTree = null
	#UI.in_game.hide()
	round_ending = true
	UI.hide_element(UI.bal_meter)
	UI.game_text.text = str("P%s scored!" % winner)
	UI.show_element(UI.game_text)
	if not is_inside_tree(): return
	tree = get_tree()
	await tree.create_timer(1).timeout
	UI.hide_element(UI.game_text)
	UI.show_element(UI.scores)
	await tree.create_timer(0.5).timeout
	UI.update_scores(scores)
	await tree.create_timer(1.5).timeout
	UI.hide_element(UI.game_text)
	round_ending = false
	tree.reload_current_scene()


@rpc("authority", "call_local", "reliable")
func end_match(winner : int) -> void:
	round_ending = true
	UI.hide_element(UI.bal_meter)
	UI.game_text.text = str("P%s won!" % winner)
	UI.show_element(UI.game_text)
	if not is_inside_tree(): return
	await get_tree().create_timer(1).timeout
	UI.hide_element(UI.game_text)
	UI.show_element(UI.scores)
	await get_tree().create_timer(0.5).timeout
	UI.update_scores(scores)
	await get_tree().create_timer(2.5).timeout
	for i : int in range(scores.size()): scores[i] = 0
	UI.hide_element(UI.game_text)
	UI.in_game.hide()
	scores_changed.emit(scores)
	round_ending = false
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")


func freeze_frame(time : float, time_scale : float = 0.1) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(time,true,false,true).timeout
	Engine.time_scale = 1
