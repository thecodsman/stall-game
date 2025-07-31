extends Control

@export var player_sprites : Array[Sprite2D]


func _ready():
	Globals.registered_controllers = []


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_START:
				var start : Button = $start
				if start.disabled: return
			_:
				if Globals.registered_controllers.has(event.device) || Globals.registered_controllers.size() >= player_sprites.size(): return
				player_sprites[Globals.registered_controllers.size()].show()
				Globals.registered_controllers.append(event.device)
				if Globals.registered_controllers.size() > 1:
					$start.disabled = false
	elif event is InputEventKey:
		match event.keycode:
			KEY_SPACE:
				if Globals.registered_controllers.has(0) || Globals.registered_controllers.size() >= player_sprites.size(): return
				player_sprites[Globals.registered_controllers.size()].show()
				Globals.registered_controllers.append(0)
				if Globals.registered_controllers.size() > 1:
					$start.disabled = false

		

func _on_start_pressed() -> void:
	UI.transition_to_scene("res://worlds/stage_select.tscn")


func _on_back_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")

