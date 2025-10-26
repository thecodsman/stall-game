extends Node


func _ready() -> void:
	if not OS.has_feature("Steam"):
		set_process(false)
		print("no steam")
		return
	print(Steam.steamInitEx(3737110, true))
	set_process(true)


func _process(_delta: float) -> void:
	Steam.run_callbacks()
