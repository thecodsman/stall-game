extends Node

@export var player_colors : Array[Color]
var camera : Camera2D
var is_online : bool = false
var registered_controllers : Array[int] # array of device ids

func freeze_frame(time : float, time_scale : float = 0.1):
	Engine.time_scale = time_scale
	await get_tree().create_timer(time,true,false,true).timeout
	Engine.time_scale = 1
