extends Node

signal scores_changed
@export var player_colors : Array[Color]
var camera : Camera2D
var is_online : bool = false
var registered_controllers : Array[int] ## array of device ids
var scores : Array[int] = [0, 0] ## scores for the match
var points_to_win : int = 3


@rpc("authority", "call_local", "reliable")
func end_round(winner : int):
	var tree : SceneTree = null
	GameText.text = str("P%s scored!" % winner)
	GameText.visible = true
	if not is_inside_tree(): return
	tree = get_tree()
	await tree.create_timer(2).timeout
	GameText.visible = false
	tree.reload_current_scene()


@rpc("authority", "call_local", "reliable")
func end_match(winner : int):
	GameText.text = str("P%s won!" % winner)
	GameText.visible = true
	if not is_inside_tree(): return
	await get_tree().create_timer(2.5).timeout
	for i in range(scores.size()): scores[i] = 0
	GameText.hide()
	UI.scores.hide()
	scores_changed.emit(scores)
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")


func freeze_frame(time : float, time_scale : float = 0.1):
	Engine.time_scale = time_scale
	await get_tree().create_timer(time,true,false,true).timeout
	Engine.time_scale = 1
