extends Control


func _on_start_pressed() -> void:
	Globals.is_online = false
	UI.transition_to_scene("res://worlds/local_menu.tscn")


func _on_online_pressed() -> void:
	Globals.is_online = true
	UI.transition_to_scene("res://worlds/connect_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _ready():
	$VBoxContainer/local.call_deferred("grab_focus")
	UI.in_game.hide()


