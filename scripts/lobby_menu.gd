extends Control


func _ready():
	Lobby.player_connected.connect(_on_player_connected)


func _on_player_connected(peer_id, player_info):
	$player2.show()
