extends Node

var camera : Camera2D

func freeze_frame(time : float, time_scale : float = 0.1):
	Engine.time_scale = time_scale
	await get_tree().create_timer(time,true,false,true).timeout
	Engine.time_scale = 1
