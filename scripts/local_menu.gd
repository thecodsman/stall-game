extends Control

@export var player_sprites : Array[Sprite2D]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if Globals.registered_controllers.has(event.device) || Globals.registered_controllers.size() >= player_sprites.size(): return
		player_sprites[Globals.registered_controllers.size()].show()
		Globals.registered_controllers.append(event.device)
		if Globals.registered_controllers.size() > 1:
			$start.disabled = false
		

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")

