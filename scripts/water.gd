extends Node2D

@export var stiffness : float = 0.015
@export var dampening : float = 0.01
@export_range(0.00001, 0.008, 0.00005) var spread : float = 0.0008
@export_range(0.0001, 0.005, 0.0001) var motion_sensitivity : float
@export var spring_number : int
@export var water_rect : ColorRect
@export var water_polygon : Polygon2D
var springs : Array[Node2D]


func _ready() -> void:
	var spring_scene : PackedScene = preload("res://stuff/water_spring.tscn")
	global_position = water_rect.global_position
	print(water_rect.size)
	for i : int in spring_number + 1:
		var spring : Node2D = spring_scene.instantiate()
		var spring_offset : float = (water_rect.size.x / spring_number)
		add_child(spring)
		spring.position.x = spring_offset * i
		springs.append(spring)
		spring.initialize()
	water_rect.hide()
	

func _physics_process(_delta: float) -> void:
	for i : int in range(springs.size()):
		var spring : Node2D = springs[i]
		spring.water_update(stiffness, dampening)
		if i > 0:
			var lspring : Node2D = springs[i-1]
			lspring.velocity += spread * (spring.height - lspring.height)
		if i < springs.size()-1:
			var rspring : Node2D = springs[i+1]
			rspring.velocity += spread * (spring.height - rspring.height)
	_update_polygon()


func _update_polygon() -> void:
	var points : PackedVector2Array
	for i : int in range(springs.size()):
		var spring : Node2D = springs[i]
		points.append(spring.position + Vector2(0, spring.height))
	points.append(water_rect.size)
	points.append(Vector2(0, water_rect.size.y))
	water_polygon.polygon = points


func splash(index : int, speed : float) -> void:
	springs[index].velocity += speed


func _on_area_2d_body_entered(body : PhysicsBody2D) -> void:
	var index : int
	var closest_distance : float = water_rect.size.x
	for i : int in range(springs.size()):
		var spring : Node2D = springs[i]
		var pos : float = spring.global_position.x
		var distance : float = body.global_position.x - pos
		if abs(distance) < closest_distance:
			index = i
			closest_distance = distance
	splash(index, body.velocity.y * motion_sensitivity)
