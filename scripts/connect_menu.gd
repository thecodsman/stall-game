extends Control

@onready var ip = $Tabs/IP/IP/ip
@onready var port = $Tabs/IP/IP/port


func _ready() -> void:
	if not OS.has_feature("Steam"):
		$Tabs/Steam.queue_free()


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
