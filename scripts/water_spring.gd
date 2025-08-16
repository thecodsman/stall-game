extends Node2D

var velocity : Vector2 = Vector2.ZERO
var force : Vector2 = Vector2.ZERO
var pos : Vector2 = Vector2.ZERO
var target_pos : Vector2 = Vector2.ZERO


func water_update(stiff : float, damp : float) -> void:
	pos = position
	velocity += Vector2(0, randf_range(0,0.025)).rotated(rotation)
	var pos_diff : Vector2 = pos - target_pos
	var loss : Vector2 = -damp * velocity
	force = -stiff * pos_diff + loss
	velocity += force
	position += velocity


func initialize() -> void:
	pos = position
	target_pos = position
	velocity = Vector2.ZERO

