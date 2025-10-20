extends Control

@onready var ip : LineEdit = $Tabs/IP/IP/ip
@onready var port : LineEdit = $Tabs/IP/IP/port
@onready var tabs : TabContainer = $Tabs


func _ready() -> void:
	if not OS.has_feature("Steam"):
		tabs.get_node("Steam").queue_free()
		tabs.get_node("IP").call_deferred("grab_focus")
	else:
		tabs.get_node("Steam").call_deferred("grab_focus")


func _on_host_pressed() -> void:
	UI.transition_to_scene("res://worlds/lobby_menu.tscn")
	await UI.on_transition
	Lobby.create_game(int(port.text))


func _on_connect_pressed() -> void:
	UI.anim.play("transition_close")
	await UI.anim.animation_finished
	Lobby.join_game(ip.text, int(port.text))
	await multiplayer.connected_to_server
	get_tree().change_scene_to_file("res://worlds/lobby_menu.tscn")
	UI.anim.play("transition_open")


func _on_steam_host_pressed() -> void:
	UI.transition_to_scene("res://worlds/lobby_menu.tscn")
	await UI.on_transition
	Lobby.steam_create_lobby()


func _on_steam_quick_match_pressed() -> void:
	Lobby.steam_start_matchmaking()
	UI.game_text.text = "FINDING MATCH"
	UI.show_element(UI.game_text)
	await multiplayer.connected_to_server
	UI.hide_element(UI.game_text)
	UI.anim.play("transition_close")
	await UI.anim.animation_finished
	get_tree().change_scene_to_file("res://worlds/lobby_menu.tscn")
	UI.anim.play("transition_open")


func _on_back_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if not event.pressed: return
		match event.button_index:
			JOY_BUTTON_B:
				if UI.onscreen_keyboard.visible: return
				_on_back_pressed()

			JOY_BUTTON_RIGHT_SHOULDER:
				tabs.current_tab = wrapi(tabs.current_tab + 1, 0, tabs.get_child_count())
				tabs.get_child(tabs.current_tab).call_deferred("grab_focus")

			JOY_BUTTON_LEFT_SHOULDER:
				tabs.current_tab = wrapi(tabs.current_tab - 1, 0, tabs.get_child_count())
				tabs.get_child(tabs.current_tab).call_deferred("grab_focus")

