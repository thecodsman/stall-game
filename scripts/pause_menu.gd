extends Control

@export var resume_button : Button

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()


func _on_mainmenu_pressed() -> void:
	get_tree().paused = false
	UI.transition_to_scene("res://worlds/main_menu.tscn")
	hide()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _on_visibility_changed() -> void:
	if visible: resume_button.grab_focus()

