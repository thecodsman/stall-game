extends Control

@onready var ip = $address/ip
@onready var port = $address/port


func _on_host_pressed() -> void:
	Lobby.create_game(int(port.text))
	get_tree().change_scene_to_file("res://worlds/lobby_menu.tscn")


func _on_connect_pressed() -> void:
	Lobby.join_game(ip.text, int(port.text))
	await multiplayer.connected_to_server
	get_tree().change_scene_to_file("res://worlds/lobby_menu.tscn")

