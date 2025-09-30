extends Node

signal scores_changed

@export var player_colors : PackedColorArray
@export var available_colors : PackedColorArray
@export var GRAY : Color
@onready var current_player_colors : PackedColorArray
var camera : Camera2D
var is_online : bool = false
var registered_controllers : Array[int] ## array of device ids
var scores : Array[int] = [] ## scores for the match
var score_line : ScoreLine
var points_to_win : int = 3
var round_ending : bool = false
var stage : Stage
var stats : Dictionary[String, float]
var serving_player : int = 0
var players_ready : int = 0


func get_serving_player() -> Player:
	var player : Player = camera.players[serving_player]
	return player


func increment_serving_player() -> void:
	serving_player = wrapi(serving_player + 1, 0, current_player_colors.size())
	if scores[serving_player] >= points_to_win - 1 && scores.min() < points_to_win - 1:
		increment_serving_player()


@rpc("any_peer", "call_remote", "reliable", 1)
func ready_for_next_round() -> void:
	players_ready += 1
	if players_ready == Lobby.players.size():
		round_ending = false
		stage.start_next_round()
		players_ready = 0


@rpc("authority", "call_local", "reliable", 1)
func end_round(winner : int) -> void:
	var tree : SceneTree = null
	slow_motion_tween(0.5)
	round_ending = true
	score_line.deactivate()
	UI.hide_element(UI.bal_meter)
	UI.game_text.text = str("P%s scored!" % winner)
	UI.show_element(UI.game_text)
	UI.combo_counter.hide()
	if not is_inside_tree(): return
	tree = get_tree()
	await tree.create_timer(1).timeout
	UI.hide_element(UI.game_text)
	UI.show_element(UI.scores)
	await tree.create_timer(0.5).timeout
	UI.update_scores(scores)
	await tree.create_timer(1.5).timeout
	increment_serving_player()
	if is_online == false:
		stage.start_next_round()
		return
	ready_for_next_round.rpc()
	ready_for_next_round()


@rpc("authority", "call_local", "reliable", 1)
func end_match(winner : int) -> void:
	slow_motion_tween(0.5)
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
	await get_tree().create_timer(1).timeout
	UI.hide_element(UI.scores)
	UI.post_match_report.update_stats(stats)
	UI.show_element(UI.post_match_report, 0)
	await get_tree().create_timer(5).timeout
	for i : int in range(scores.size()): scores[i] = 0
	UI.hide_element(UI.game_text)
	UI.hide_element(UI.post_match_report)
	UI.in_game.hide()
	scores_changed.emit(scores)
	round_ending = false
	stats.clear()
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")


func freeze_frame(time : float, time_scale : float = 0.1) -> void:
	if Engine.time_scale != 1: return
	Engine.time_scale = time_scale
	await get_tree().create_timer(time,true,false,true).timeout
	Engine.time_scale = 1


func slow_motion_tween(duration : float, tween_time : float = 0.5, target_time_scale : float = 0.25) -> void:
	var tween : Tween = create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(Engine, ^"time_scale", target_time_scale, tween_time)
	tween.tween_property(Engine, ^"time_scale", 1, tween_time * target_time_scale).set_delay(duration * target_time_scale)
