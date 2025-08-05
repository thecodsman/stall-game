extends Control

@onready var player_sprites : HBoxContainer = $SubViewportContainer/game/players


func _ready():
	Globals.registered_controllers = []


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_START:
				var start : Button = $start
				if start.disabled: return
			_:
				if Globals.registered_controllers.has(event.device) || Globals.registered_controllers.size() >= player_sprites.get_child_count(): return
				player_sprites.get_child(Globals.registered_controllers.size()).show()
				Globals.registered_controllers.append(event.device)
				if Globals.registered_controllers.size() > 1:
					$start.disabled = false
	elif event is InputEventKey:
		match event.keycode:
			KEY_SPACE:
				if Globals.registered_controllers.has(-1) || Globals.registered_controllers.size() >= player_sprites.get_child_count(): return
				player_sprites.get_child(Globals.registered_controllers.size()).show()
				Globals.registered_controllers.append(-1)
				if Globals.registered_controllers.size() > 1:
					$start.disabled = false

		

func _on_start_pressed() -> void:
	UI.transition_to_scene("res://worlds/stage_select.tscn")


func _on_back_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")
