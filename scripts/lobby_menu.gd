extends Control

@export var player_sprites : Array[Sprite2D]

func _ready():
	Lobby.player_connected.connect(_on_player_connected)
	if Lobby.players.size() > 1:
		show_player_2_sprite()
		$start.hide()


func show_player_2_sprite():
	player_sprites[1].show()

func _on_player_connected(_peer_id, _player_info):
	print("player connected")
	show_player_2_sprite()
	if is_multiplayer_authority():
		$start.disabled = false
	else:
		$start.hide()


func _on_start_pressed() -> void:
	go_to_stage_select.rpc()


@rpc("call_local", "reliable")
func go_to_stage_select() -> void:
	get_tree().change_scene_to_file("res://worlds/stage_select.tscn")
