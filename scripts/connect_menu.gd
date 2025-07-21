extends Control

@onready var ip = $Tabs/IP/IP/ip
@onready var port = $Tabs/IP/IP/port
@onready var tabs : TabContainer = $Tabs


func _ready() -> void:
	if not OS.has_feature("Steam"):
		tabs.get_node("Steam").queue_free()
		tabs.get_node("IP").call_deferred("grab_focus")
	else:
		tabs.get_node("Steam").call_deferred("grab_focus")


func _on_host_pressed() -> void:
	Lobby.create_game(int(port.text))
	UI.transition_to_scene("res://worlds/lobby_menu.tscn")


func _on_connect_pressed() -> void:
	Lobby.join_game(ip.text, int(port.text))
	await multiplayer.connected_to_server
	UI.transition_to_scene("res://worlds/lobby_menu.tscn")


func _on_steam_host_pressed() -> void:
	Lobby.steam_create_lobby()
	await Steam.lobby_created
	UI.transition_to_scene("res://worlds/lobby_menu.tscn")


func _on_back_pressed() -> void:
	UI.transition_to_scene("res://worlds/main_menu.tscn")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if not event.pressed: return
		match event.button_index:
			JOY_BUTTON_B:
				_on_back_pressed()

			JOY_BUTTON_RIGHT_SHOULDER:
				tabs.current_tab = wrapi(tabs.current_tab + 1, 0, tabs.get_child_count())
				tabs.get_child(tabs.current_tab).call_deferred("grab_focus")

			JOY_BUTTON_LEFT_SHOULDER:
				tabs.current_tab = wrapi(tabs.current_tab - 1, 0, tabs.get_child_count())
				tabs.get_child(tabs.current_tab).call_deferred("grab_focus")
