extends Control

@export var player_boxes : HBoxContainer
@export var character_select : CharacterSelect
const CONNECT_MENU_UID : String = "uid://jhomeys3bfhg"


func _ready() -> void:
	print("lobby menu loaded")
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.player_assigned_index.connect(_on_player_index_assigned)
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
	if is_multiplayer_authority():
		Lobby.set_player_index(0, 1, {})
	else:
		print(Lobby.player_indices)
	


@rpc("any_peer", "call_remote", "reliable")
func register_player(player : int, id : int) -> void:
	var color : Color = Globals.player_colors[player]
	var colorI : int = Globals.available_colors.find(color)
	var player_box : PlayerBox = player_boxes.get_child(player)
	while Globals.current_player_colors.has(color):
		colorI = wrapi(colorI + 1, 0, Globals.available_colors.size())
		color = Globals.available_colors[colorI]
	if Globals.current_player_colors.size() < player + 1:
		Globals.current_player_colors.resize(player + 1)
	Globals.current_player_colors[player] = color
	if Globals.scores.size() < player + 1:
		Globals.scores.resize(player + 1)
		Globals.scores[player] = 0
	player_box.name = str(id)
	player_box.color = color
	player_box.show()
	player_box.player_joined = true
	character_select.new_player(player)


@rpc("authority", "call_local", "reliable")
func deregister_player(index : int) -> void:
	var player_box : PlayerBox = player_boxes.get_child(index)
	character_select.remove_player(index)
	Globals.current_player_colors.remove_at(index)
	player_box.player_joined = false
	player_box.color = Globals.GRAY
	if index > 1:
		player_box.hide()
	if not Lobby.player_indices.values().has(index+1):
		return
	for i : int in range(Lobby.player_indices.size()):
		var id : int = Lobby.player_indices.keys()[i]
		var player : int = Lobby.player_indices[id]
		if i <= index: continue
		if not is_multiplayer_authority(): continue
		deregister_player.rpc(player)
		Lobby.set_player_index.rpc(player - 1, id, Lobby.player_indices)


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


func _on_player_index_assigned(peer_id : int) -> void:
	register_player(Lobby.player_indices[peer_id], peer_id)
	if peer_id != multiplayer.get_unique_id(): return
	for i : int in range(Lobby.player_indices.size()):
		var player : int = Lobby.player_indices.keys()[i]
		var index : int = Lobby.player_indices[player]
		if player == multiplayer.get_unique_id(): continue
		if Globals.current_player_colors[index] != Color.BLACK: continue # dont register already registered players
		register_player(index, player)


func _on_player_connected(_peer_id : int, _player_info : Dictionary) -> void:
	if is_multiplayer_authority():
		$start.show()
		UI.hide_element(UI.game_text)
	else:
		$start.hide()


func _on_player_disconnected(peer_id : int) -> void:
	print("player disconnected")
	deregister_player(Lobby.player_indices[peer_id])


func _on_start_pressed() -> void:
	go_to_stage_select.rpc()


func _on_player_selection_changed(player : int, character : CharacterSelectIcon) -> void:
	update_player_portrait.rpc(player, character.get_path())


@rpc("any_peer", "call_local", "reliable")
func update_player_portrait(player : int, character_icon : NodePath) -> void:
	var player_box : PlayerBox = player_boxes.get_child(player)
	var character : CharacterSelectIcon = get_node(character_icon)
	player_box.portrait = character.portrait
	player_box.color = Globals.current_player_colors[player]


@rpc("call_local", "reliable")
func go_to_stage_select() -> void:
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")


func _on_back_pressed() -> void:
	if Lobby.lobby_id != 0:
		Steam.leaveLobby(Lobby.lobby_id)
	else:
		UI.transition_to_scene(CONNECT_MENU_UID)
		await UI.on_transition
		if is_multiplayer_authority(): Lobby.peer.close()
		else: Lobby.peer.disconnect_peer(1)
		
