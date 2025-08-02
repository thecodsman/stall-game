extends Sprite2D

var shaking : bool = false
var shaking_intensity : float
var shaking_interval : int

func _physics_process(_delta : float) -> void:
	if shaking && not Engine.get_physics_frames() % shaking_interval:
		offset = Vector2(randf_range(-shaking_intensity, shaking_intensity), randf_range(-shaking_intensity, shaking_intensity))
	elif not shaking:
		offset = Vector2.ZERO


func shake(intensity : float, time : float, interval : int):
	shaking = true
	shaking_intensity = intensity
	shaking_interval = interval
	await get_tree().create_timer(time).timeout
	shaking = false
