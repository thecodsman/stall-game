extends Control

@onready var player_sprites : HBoxContainer = $SubViewportContainer/game/players


func _ready() -> void:
	Globals.registered_controllers.clear()
	Globals.scores.clear()
	Globals.current_player_colors.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_RIGHT_SHOULDER:
				if not event.pressed: return
				var player : int = Globals.registered_controllers.find(event.device)
				switch_color(player, 1)
			JOY_BUTTON_LEFT_SHOULDER:
				if not event.pressed: return
				var player : int = Globals.registered_controllers.find(event.device)
				switch_color(player, -1)
			_:
				if Globals.registered_controllers.has(event.device) || Globals.registered_controllers.size() >= player_sprites.get_child_count(): return
				register_new_player(event.device)
	elif event is InputEventKey:
		if not event.pressed: return
		match event.keycode:
			KEY_LEFT:
				var player : int = Globals.registered_controllers.find(-1)
				switch_color(player, -1)
			KEY_RIGHT:
				var player : int = Globals.registered_controllers.find(-1)
				switch_color(player, 1)
			KEY_SPACE:
				if Globals.registered_controllers.has(-1) || Globals.registered_controllers.size() >= player_sprites.get_child_count(): return
				register_new_player(-1)


func switch_color(player : int, dir : int) -> void:
	if player < 0: return
	var color : Color = Globals.current_player_colors[player]
	var new_color : Color = Globals.available_colors[wrapf(Globals.available_colors.find(color) + dir, 0, Globals.available_colors.size())]
	while Globals.current_player_colors.has(new_color):
		new_color = Globals.available_colors[wrapf(Globals.available_colors.find(new_color) + dir, 0, Globals.available_colors.size())]
	Globals.current_player_colors[player] = new_color
	player_sprites.get_child(player).get_child(0).modulate = new_color


func register_new_player(device : int) -> void:
	var color : Color = Globals.player_colors[Globals.registered_controllers.size()]
	var colorI : int = Globals.available_colors.find(color)
	var player_sprite = player_sprites.get_child(Globals.registered_controllers.size())
	while Globals.current_player_colors.has(color):
		colorI = wrapi(colorI + 1, 0, Globals.available_colors.size())
		color = Globals.available_colors[colorI]
	Globals.current_player_colors.append(color)
	player_sprite.get_child(0).modulate = color
	player_sprite.show()
	Globals.registered_controllers.append(device)
	Globals.scores.append(0)
	if Globals.registered_controllers.size() > 1:
		$start.disabled = false
		

func _on_start_pressed() -> void:
	UI.transition_to_scene("res://worlds/stage_select.tscn")


func _on_back_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")
