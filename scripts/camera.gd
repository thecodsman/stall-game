extends Camera2D

var shaket : int = 0
var shakei : float = 0

func physics_process(delta : float):
	if shaket > 0:
		offset = Vector2(randf_range(-shakei,shakei),randf_range(-shakei,shakei))
		shaket -= 1

func screen_shake(frames : int, intensity : float):
	shaket = frames
	shakei = intensity
