extends Node2D

@export var splash_particles_scene : PackedScene
var velocity : Vector2 = Vector2.ZERO
var force : Vector2 = Vector2.ZERO
var pos : Vector2 = Vector2.ZERO
var target_pos : Vector2 = Vector2.ZERO
var surface_tension : float = 0 ## position needed in order so splash up water droplets and crud
var boundary : float = 0


func water_update(stiff : float, damp : float) -> void:
	pos = position
	velocity += Vector2(0, randf_range(0,0.025)).rotated(rotation)
	var pos_diff : Vector2 = pos - target_pos
	var loss : Vector2 = -damp * velocity
	force = -stiff * pos_diff + loss
	velocity += force
	position += velocity
	var velocity_inwards : float = (velocity * Vector2(0,1).rotated(rotation)).rotated(-rotation).x
	if velocity.length() < surface_tension || velocity_inwards > 0: return
	var velocity_mult : float = 75
	var base_spawn_rate : int = 72
	if Engine.get_physics_frames() % clampi(base_spawn_rate - int(velocity.length() * velocity_mult), 1, base_spawn_rate): return
	spawn_particles(Vector2(0,-velocity.length()).rotated(randf_range(-PI/8,PI/8)) * velocity_mult)


func spawn_particles(vel : Vector2) -> void:
	var particles : GPUParticles2D = splash_particles_scene.instantiate()
	add_child(particles)
	particles.emit_particle(Transform2D.IDENTITY, vel, Color.WHITE, Color.WHITE, particles.EMIT_FLAG_VELOCITY)
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()


func initialize() -> void:
	pos = position
	target_pos = position
	velocity = Vector2.ZERO
