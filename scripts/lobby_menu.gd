extends Control

@export var player_sprites : HBoxContainer

func _ready():
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_index = clampi(Lobby.players.size() - 1, 0, 3)
	Globals.scores.clear()
	Globals.current_player_colors.clear()
	for i in range(Lobby.players.size()):
		register_player(i)


func register_player(player : int):
	var color : Color = Globals.player_colors[player]
	var colorI : int = Globals.available_colors.find(color)
	var player_portrait : Panel = player_sprites.get_child(player)
	while Globals.current_player_colors.has(color):
		colorI = wrapi(colorI + 1, 0, Globals.available_colors.size())
		color = Globals.available_colors[colorI]
	Globals.current_player_colors.append(color)
	Globals.scores.append(0)
	player_portrait.get_child(0).modulate = color
	player_portrait.show()


@rpc("any_peer", "call_local", "reliable")
func switch_color(player : int, dir : int):
	if player < 0: return
	var color : Color = Globals.current_player_colors[player]
	var new_color : Color = Globals.available_colors[wrapi(Globals.available_colors.find(color) + dir, 0, Globals.available_colors.size())]
	while Globals.current_player_colors.has(new_color):
		new_color = Globals.available_colors[wrapi(Globals.available_colors.find(new_color) + dir, 0, Globals.available_colors.size())]
	Globals.current_player_colors[player] = new_color
	player_sprites.get_child(player).get_child(0).modulate = new_color


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_RIGHT_SHOULDER:
				if not event.pressed: return
				var player = Lobby.player_index
				switch_color.rpc(player, 1)
			JOY_BUTTON_LEFT_SHOULDER:
				if not event.pressed: return
				var player = Lobby.player_index
				switch_color.rpc(player, -1)
	elif event is InputEventKey:
		if not event.pressed: return
		match event.keycode:
			KEY_LEFT:
				var player = Lobby.player_index
				switch_color.rpc(player, -1)
			KEY_RIGHT:
				var player = Lobby.player_index
				switch_color.rpc(player, 1)


func _on_player_connected(_peer_id, _player_info):
	print("player connected")
	register_player(Lobby.players.size() - 1)
	if is_multiplayer_authority():
		$start.show()
		$start.disabled = false
	else:
		$start.hide()


func _on_start_pressed() -> void:
	go_to_stage_select.rpc()


@rpc("call_local", "reliable")
func go_to_stage_select() -> void:
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")
