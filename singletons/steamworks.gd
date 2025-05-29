extends Node

func _ready():
	if not OS.has_feature("Steam"):
		set_process(false)
		return
	Steam.steamInit(3737110)
	set_process(true)

func _process(_delta: float):
	Steam.run_callbacks()
