extends Node2D

@export var stiffness : float = 0.015
@export var dampening : float = 0.01
@export_range(0.00001, 0.008, 0.00005) var spread : float = 0.0008
@export_range(0.0001, 0.005, 0.0001) var motion_sensitivity : float
@export var surface_tension : float = 0 ## velocity needed in order so splash up water droplets and crud
@export var active_sides : Array[Vector2i] = [Vector2i.UP]
@export var fixed_points : Dictionary[int, Array] ## fixed points for the water polygon, put (0,0) in the `active_sides` to change when the fixed points are added
@export var spring_counts : Array[int] ## springs per side
@export var water_rect : ColorRect
@export var water_area : Area2D
@export var water_polygon : Polygon2D
var springs : Array[Node2D]


func _ready() -> void:
	water_rect.hide()
	water_area.body_entered.connect(_on_area_2d_body_entered)
	water_area.body_exited.connect(_on_area_2d_body_exited)
	water_area.collision_mask = 0b0110
	water_area.collision_layer = 16
	global_position = water_rect.global_position
	var spring_scene : PackedScene = preload("res://stuff/water_spring.tscn")
	var side : int = -1
	for i : int in range(active_sides.size()):
		var normal : Vector2 = Vector2(active_sides[i])
		var spring_count : int = spring_counts[wrapi(i, 0, spring_counts.size())]
		var spring_offset : float 
		var spring_origin : Vector2
		side += 1
		match normal:
			Vector2.UP: spring_origin = Vector2.ZERO
			Vector2.RIGHT: spring_origin = Vector2.RIGHT
			Vector2.DOWN: spring_origin = Vector2.ONE
			Vector2.LEFT: spring_origin = Vector2.DOWN
			Vector2.ZERO: return
		if abs(normal.y): spring_offset = (water_rect.size.x / spring_count)
		elif abs(normal.x): spring_offset = (water_rect.size.y / spring_count)
		for j : int in spring_count + 1:
			if active_sides.has(Vector2i(normal.rotated(PI/2).round())) && j == spring_count: continue
			if active_sides.has(Vector2i(normal.rotated(-PI/2).round())) && j == 0: continue
			var spring : Node2D = spring_scene.instantiate()
			var spring_pos : Vector2 = (spring_origin * water_rect.size) + Vector2(0, spring_offset * j).rotated(normal.angle())
			if fixed_points.size() > 0 && fixed_points.values()[min(side,fixed_points.size()-1)].has(spring_pos / water_rect.size): continue
			add_child(spring)
			spring.position = spring_pos
			spring.rotation = normal.rotated(PI/2).angle()
			spring.surface_tension = surface_tension
			spring.boundary = spring_offset * 0.8
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
		if abs((spring.position - spring.target_pos).rotated(spring.rotation).x) > spring.boundary:
			var dir : int = int(signf(spring.position.rotated(spring.rotation).x))
			var index : int = wrapi(i+dir,0,springs.size())
			springs[index].velocity = spring.velocity
			spring.velocity *= 0.5
			#spring.position = spring.target_pos
			#springs[index].position = spring.position
	_update_polygon()


func _update_polygon() -> void:
	var points : PackedVector2Array = []
	var side : int = 0
	for i : int in range(springs.size()):
		if not i % spring_counts[clampi(side, 0, spring_counts.size()-1)]:
			if fixed_points.has(side):
				points = add_fixed_points(points, side)
			side = clampi(side + 1, 0, active_sides.size() - 1)
		var spring : Node2D = springs[i]
		points.append(spring.position)
	if fixed_points.has(-1):
		points = add_fixed_points(points, -1)
	points = Geometry2D.merge_polygons(points, PackedVector2Array())[0]
	water_polygon.polygon = points
	$caustics.polygon = points
	$foam.polygon = points


func add_fixed_points(points : PackedVector2Array, side : int) -> PackedVector2Array:
		for i : int in range(fixed_points[side].size()):
			var fixed_point : Vector2 = fixed_points[side][i]
			points.append(water_rect.size * fixed_point)
		return points


func splash(index : int, speed : Vector2) -> void:
	if not springs.get(index): return
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
	splash(wrapi(index + 1, 0, springs.size()), body.velocity.rotated(PI/4) * motion_sensitivity * -1.25)
	splash(wrapi(index - 1, 0, springs.size()), body.velocity.rotated(-PI/4) * motion_sensitivity * -1.25)


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
	splash(wrapi(index + 1, 0, springs.size()), body.velocity.rotated(PI/4) * motion_sensitivity * -1.25)
	splash(wrapi(index - 1, 0, springs.size()), body.velocity.rotated(-PI/4) * motion_sensitivity * -1.25)
