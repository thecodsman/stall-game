extends Control

@export var player_sprites : Array[Sprite2D]

func _ready():
	Lobby.player_connected.connect(_on_player_connected)


func _on_player_connected(peer_id, player_info):
	player_sprites[1].show()
	if is_multiplayer_authority():
		$start.disabled = false
	else:
		$start.hide()


func _on_start_pressed() -> void:
	go_to_stage_select.rpc()


@rpc("call_local", "reliable")
func go_to_stage_select() -> void:
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")
