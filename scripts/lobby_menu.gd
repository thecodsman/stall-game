extends Control

@export var player_boxes : HBoxContainer
@export var character_select : CharacterSelect


func _ready() -> void:
	Lobby.player_connected.connect(_on_player_connected)
	Globals.scores.clear()
	Globals.current_player_colors.clear()
	character_select.player_selection_changed.connect(_on_player_selection_changed)
	character_select.character_selected.connect(func(player : int) -> void:
		player_boxes.get_child(player).character_selected = true
		if character_select.selected.size() != Lobby.players.size(): return
		if character_select.selected.values().has(null): return
		$start.disabled = false
	)
	character_select.character_deselected.connect(func(player : int) -> void:
		player_boxes.get_child(player).character_selected = false
		$start.disabled = true
	)
	for i : int in range(Lobby.players.size()):
		print(i)
		register_player(i)


func register_player(player : int) -> void:
	var color : Color = Globals.player_colors[player]
	var colorI : int = Globals.available_colors.find(color)
	var player_box : PlayerBox = player_boxes.get_child(player)
	while Globals.current_player_colors.has(color):
		colorI = wrapi(colorI + 1, 0, Globals.available_colors.size())
		color = Globals.available_colors[colorI]
	Globals.current_player_colors.append(color)
	Globals.scores.append(0)
	player_box.color = color
	player_box.show()
	player_box.player_joined = true
	character_select.new_player(player)


@rpc("any_peer", "call_local", "reliable")
func switch_color(player : int, dir : int) -> void:
	if player < 0: return
	var color : Color = Globals.current_player_colors[player]
	var new_color : Color = Globals.available_colors[wrapi(
			Globals.available_colors.find(color) + dir, 0,
			Globals.available_colors.size()
			)]
	while Globals.current_player_colors.has(new_color):
		new_color = Globals.available_colors[wrapi(
				Globals.available_colors.find(new_color) + dir, 0,
				Globals.available_colors.size()
				)]
	Globals.current_player_colors[player] = new_color
	player_boxes.get_child(player).get_child(0).modulate = new_color


func _unhandled_input(event: InputEvent) -> void:
	var player : int = Lobby.player_index
	if event is InputEventJoypadButton:
		if not event.pressed: return
		match event.button_index:
			JOY_BUTTON_RIGHT_SHOULDER:
				switch_color.rpc(player, 1)
			JOY_BUTTON_LEFT_SHOULDER:
				switch_color.rpc(player, -1)
			JOY_BUTTON_START:
				if is_multiplayer_authority() == false: return
				_on_start_pressed()
	elif event is InputEventKey && Input.is_key_pressed(KEY_SHIFT):
		if not event.pressed: return
		match event.keycode:
			KEY_LEFT:
				switch_color.rpc(player, -1)
			KEY_RIGHT:
				switch_color.rpc(player, 1)


func _on_player_connected(_peer_id : int, _player_info : Dictionary) -> void:
	print("player connected")
	register_player(Lobby.players.size() - 1)
	if is_multiplayer_authority():
		$start.show()
		Lobby.set_player_index.rpc_id(_peer_id, Lobby.players.size() - 1)
	else:
		$start.hide()


func _on_start_pressed() -> void:
	go_to_stage_select.rpc()


func _on_player_selection_changed(player : int, character : CharacterSelectIcon) -> void:
	update_player_portrait.rpc(player, character.get_path())


@rpc("any_peer", "call_local", "reliable")
func update_player_portrait(player : int, character_icon : NodePath) -> void:
	var player_box : PlayerBox = player_boxes.get_child(player)
	var character : CharacterSelectIcon = get_node(character_icon)
	player_box.portrait = character.portrait


@rpc("call_local", "reliable")
func go_to_stage_select() -> void:
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")
