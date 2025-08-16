extends Node2D

@export var stiffness : float = 0.015
@export var dampening : float = 0.01
@export_range(0.00001, 0.008, 0.00005) var spread : float = 0.0008
@export_range(0.0001, 0.005, 0.0001) var motion_sensitivity : float
@export var active_sides : Array[Vector2i] = [Vector2i.UP]
@export var fixed_points : Array[Vector2] = [Vector2.DOWN, Vector2.ONE] ## fixed points for the water polygon
@export var spring_number : int ## springs PER SIDE
@export var water_rect : ColorRect
@export var water_polygon : Polygon2D
var springs : Array[Node2D]


func _ready() -> void:
	water_rect.hide()
	var spring_scene : PackedScene = preload("res://stuff/water_spring.tscn")
	global_position = water_rect.global_position
	print(water_rect.size)
	for i : int in range(active_sides.size()):
		var normal : Vector2 = active_sides[i]
		var spring_offset : float 
		var spring_origin : Vector2
		match normal:
			Vector2.UP: spring_origin = Vector2.ZERO
			Vector2.RIGHT: spring_origin = Vector2.RIGHT
			Vector2.DOWN: spring_origin = Vector2.ONE
			Vector2.LEFT: spring_origin = Vector2.DOWN
		if abs(normal.y): spring_offset = (water_rect.size.x / spring_number)
		elif abs(normal.x): spring_offset = (water_rect.size.y / spring_number)
		for j : int in spring_number + 1:
			if active_sides.has(Vector2i(normal.rotated(PI/2).round())) && j == spring_number: continue
			if active_sides.has(Vector2i(normal.rotated(-PI/2).round())) && j == 0: continue
			var spring : Node2D = spring_scene.instantiate()
			add_child(spring)
			spring.position = (spring_origin * water_rect.size) + Vector2(0, spring_offset * j).rotated(normal.angle())
			spring.rotation = normal.rotated(PI/2).angle()
			spring.initialize()
			springs.append(spring)
	

func _physics_process(_delta: float) -> void:
	for i : int in range(springs.size()):
		var spring : Node2D = springs[i]
		spring.water_update(stiffness, dampening)
		if i > 0:
			var lspring : Node2D = springs[i-1]
			lspring.velocity += spread * (spring.pos - lspring.pos)
		if i < springs.size()-1:
			var rspring : Node2D = springs[i+1]
			rspring.velocity += spread * (spring.pos - rspring.pos)
	_update_polygon()


func _update_polygon() -> void:
	var points : PackedVector2Array
	for i : int in range(springs.size()):
		var spring : Node2D = springs[i]
		points.append(spring.position)
	for i : int in range(fixed_points.size()):
		var fixed_point : Vector2 = fixed_points[i]
		points.append(water_rect.size * fixed_point)
	water_polygon.polygon = points


func splash(index : int, speed : Vector2) -> void:
	springs[index].velocity += speed


func _on_area_2d_body_entered(body : PhysicsBody2D) -> void:
	var index : int
	var closest_distance : Vector2 = water_rect.size
	for i : int in range(springs.size()):
		var spring : Node2D = springs[i]
		var pos : Vector2 = spring.global_position
		var distance : Vector2 = body.global_position - pos
		if distance.length() < closest_distance.length():
			closest_distance = distance
			index = i
	splash(index, body.velocity * motion_sensitivity)


func _on_area_2d_body_exited(body : PhysicsBody2D) -> void:
	var index : int
	var closest_distance : Vector2 = water_rect.size
	for i : int in range(springs.size()):
		var spring : Node2D = springs[i]
		var pos : Vector2 = spring.global_position
		var distance : Vector2 = body.global_position - pos
		if distance.length() < closest_distance.length():
			closest_distance = distance
			index = i
	splash(index, body.velocity * motion_sensitivity)
