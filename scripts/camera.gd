extends Camera2D

var shaket : int = 0
var shakei : float = 0
var shakef : int = 1 ## shake every X amount of frames

func _ready():
	Globals.camera = self

func _physics_process(delta : float):
	if Engine.get_physics_frames() % shakef: return
	if shaket > 0:
		offset = Vector2(randf_range(-shakei,shakei),randf_range(-shakei,shakei))
		shaket -= 1
	else:
		offset = Vector2.ZERO

func screen_shake(frames : int, intensity : float, frequency : int = 1):
	shaket = frames
	shakei = intensity
	shakef = frequency
