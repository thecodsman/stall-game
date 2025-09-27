extends Control

@export var player_boxes : HBoxContainer
@export var character_select : CharacterSelect


func _ready() -> void:
	Globals.registered_controllers.clear()
	Globals.scores.clear()
	Globals.current_player_colors.clear()
	character_select.player_selection_changed.connect(_on_player_selection_changed)
	character_select.character_selected.connect(func(player : int) -> void:
		player_boxes.get_child(player).character_selected = true
		if character_select.selected.size() != Globals.registered_controllers.size(): return
		if character_select.selected.values().has(null): return
		$start.disabled = false
		)
	character_select.character_deselected.connect(func(player : int) -> void:
		player_boxes.get_child(player).character_selected = false
		$start.disabled = true
		)


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
				if Globals.registered_controllers.has(event.device) || Globals.registered_controllers.size() >= player_boxes.get_child_count(): return
				register_player(event.device)
	elif event is InputEventKey:
		if not event.pressed: return
		match event.keycode:
			KEY_LEFT:
				if not Input.is_key_pressed(KEY_SHIFT): return
				var player : int = Globals.registered_controllers.find(-1)
				switch_color(player, -1)
			KEY_RIGHT:
				if not Input.is_key_pressed(KEY_SHIFT): return
				var player : int = Globals.registered_controllers.find(-1)
				switch_color(player, 1)
			KEY_SPACE:
				if Globals.registered_controllers.has(-1) || Globals.registered_controllers.size() >= player_boxes.get_child_count(): return
				register_player(-1)


func switch_color(player : int, dir : int) -> void:
	if player < 0: return
	var color : Color = Globals.current_player_colors[player]
	var new_color : Color = Globals.available_colors[wrapf(Globals.available_colors.find(color) + dir, 0, Globals.available_colors.size())]
	while Globals.current_player_colors.has(new_color):
		new_color = Globals.available_colors[wrapf(Globals.available_colors.find(new_color) + dir, 0, Globals.available_colors.size())]
	Globals.current_player_colors[player] = new_color
	player_boxes.get_child(player).color = new_color


func register_player(device : int) -> void:
	var color : Color = Globals.player_colors[Globals.registered_controllers.size()]
	var colorI : int = Globals.available_colors.find(color)
	var player_box : PlayerBox = player_boxes.get_child(Globals.registered_controllers.size())
	while Globals.current_player_colors.has(color):
		colorI = wrapi(colorI + 1, 0, Globals.available_colors.size())
		color = Globals.available_colors[colorI]
	Globals.current_player_colors.append(color)
	player_box.color = color
	player_box.player_joined = true
	player_boxes.get_child(clampi(Globals.registered_controllers.size() + 1, 0, 4)).show()
	character_select.new_player(Globals.registered_controllers.size())
	Globals.registered_controllers.append(device)
	Globals.scores.append(0)
		

func _on_start_pressed() -> void:
	UI.transition_to_scene("res://worlds/stage_select.tscn")


func _on_back_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")


func _on_player_selection_changed(player : int, character : CharacterSelectIcon) -> void:
	var player_box : PlayerBox = player_boxes.get_child(player)
	player_box.portrait = character.portrait
