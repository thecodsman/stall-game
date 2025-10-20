class_name CharacterSelect extends GridContainer

signal player_selection_changed(player : int, character : CharacterSelectIcon)
signal character_selected(player : int)
signal character_deselected(player : int)

var focusing : Dictionary [int,CharacterSelectIcon]
var selected : Dictionary [int,CharacterSelectIcon]
var last_joy_vectors : Dictionary [int,Vector2]

enum {
	LEFT,
	DOWN,
	RIGHT,
	UP
}


func _unhandled_input(event: InputEvent) -> void:
	match event.get_class():
		"InputEventJoypadButton": _on_joypad_button_event(event)
		"InputEventJoypadMotion": _on_joypad_motion_event(event)
		"InputEventKey": _on_key_input_event(event)


func _on_joypad_button_event(event : InputEventJoypadButton) -> void:
	if not event.pressed: return
	if not Globals.registered_controllers.has(event.device) && Globals.is_online == false: return
	var player : int = (
			Globals.registered_controllers.find(event.device) if not Globals.is_online
			else Lobby.player_index
	)
	match event.button_index:
		JOY_BUTTON_A:
			select_character.rpc(player)
		JOY_BUTTON_B:
			deselect_character.rpc(player)


func _on_joypad_motion_event(event : InputEventJoypadMotion) -> void:
	if not Globals.registered_controllers.has(event.device) && Globals.is_online == false: return
	if selected.get(Globals.registered_controllers.find(event.device)): return
	if event.axis != JOY_AXIS_LEFT_X && event.axis != JOY_AXIS_LEFT_Y: return
	var player : int = (
			Globals.registered_controllers.find(event.device) if not Globals.is_online
			else Lobby.player_index
	)
	if event.axis_value > 0.95 && last_joy_vectors[event.device][event.axis] < 0.95:
		scroll.rpc(event.axis + 2, player)
	elif event.axis_value < -0.95 && last_joy_vectors[event.device][event.axis] > -0.95:
		scroll.rpc(event.axis, player)
	last_joy_vectors.set(event.device, Vector2(Input.get_joy_axis(event.device, JOY_AXIS_LEFT_X), Input.get_joy_axis(event.device, JOY_AXIS_LEFT_Y)))


func _on_key_input_event(event : InputEventKey) -> void:
	if not Globals.registered_controllers.has(-1) && not Globals.is_online: return
	if not event.pressed: return
	if Input.is_key_pressed(KEY_SHIFT): return
	var player : int = Globals.registered_controllers.find(-1)
	match event.keycode:
		KEY_SPACE, KEY_ENTER:
			select_character(player)
		KEY_LEFT:
			scroll(LEFT, player)
		KEY_RIGHT:
			scroll(RIGHT, player)
		KEY_UP:
			scroll(UP, player)
		KEY_DOWN:
			scroll(DOWN, player)


func new_player(player : int) -> void:
	focusing.set(player, get_child(0))
	get_child(0).focusing.append(player)


@rpc("any_peer", "call_local", "reliable")
func scroll(dir : int, player : int) -> void:
	var icon : CharacterSelectIcon = focusing[player]
	if not icon: return
	match dir:
		UP:
			if not icon.focus_neighbor_top: return
			var next_icon : CharacterSelectIcon = icon.get_node(icon.focus_neighbor_top)
			icon.focusing.erase(player)
			next_icon.focusing.append(player)
			focusing[player] = next_icon
		RIGHT:
			if not icon.focus_neighbor_right: return
			var next_icon : CharacterSelectIcon = icon.get_node(icon.focus_neighbor_right)
			icon.focusing.erase(player)
			next_icon.focusing.append(player)
			focusing[player] = next_icon
		DOWN:
			if not icon.focus_neighbor_bottom: return
			var next_icon : CharacterSelectIcon = icon.get_node(icon.focus_neighbor_bottom)
			icon.focusing.erase(player)
			next_icon.focusing.append(player)
			focusing[player] = next_icon
		LEFT:
			if not icon.focus_neighbor_left: return
			var next_icon : CharacterSelectIcon = icon.get_node(icon.focus_neighbor_left)
			icon.focusing.erase(player)
			next_icon.focusing.append(player)
			focusing[player] = next_icon
	icon = focusing[player]
	player_selection_changed.emit(player, icon)


@rpc("any_peer", "call_local", "reliable")
func select_character(player : int) -> void:
	if selected.get(player): return
	if focusing[player].locked: return
	focusing[player].selected.append(player)
	selected[player] = focusing[player]
	focusing[player].focusing.erase(player)
	focusing[player] = null
	character_selected.emit(player)


@rpc("any_peer", "call_local", "reliable")
func deselect_character(player : int) -> void:
	if not selected.get(player): return
	selected[player].focusing.append(player)
	focusing[player] = selected[player]
	selected[player].selected.erase(player)
	selected[player] = null
	character_deselected.emit(player)


func get_player(device : int) -> int:
	if Globals.is_online:
		return Lobby.player_index
	else:
		return Globals.registered_controllers.find(device)
