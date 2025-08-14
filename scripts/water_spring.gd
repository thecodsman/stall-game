extends Node2D

var velocity : float = 0
var force : float = 0
var height : float = 0
var target_height : float = 0


func water_update(stiff : float, damp : float) -> void:
	height = position.y
	height += randf_range(0,0.5)
	var height_diff : float = height - target_height
	var loss : float = -damp * velocity
	force = -stiff * height_diff + loss
	velocity += force
	position.y += velocity


func initialize() -> void:
	height = position.y
	target_height = position.y
	velocity = 0

